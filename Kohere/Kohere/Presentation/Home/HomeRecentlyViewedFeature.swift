//
//  HomeRecentlyViewedFeature.swift
//  Kohere
//
//  Created by soomin on 7/31/26.
//

import ComposableArchitecture
import Foundation

private extension HomeRecentlyViewedFeature {
    enum EffectID {
        static let recentListings = "HomeFeature.recentListings"
        static let exchangeRate = "HomeFeature.exchangeRate"
        static let favorite = "HomeFeature.favorite"
    }
}

@Reducer
struct HomeRecentlyViewedFeature {
    @Dependency(\.listingClient)
    var listingClient
    @Dependency(\.fetchKRWToUSDExchangeRateUseCase)
    var fetchKRWToUSDExchangeRateUseCase
    @Dependency(\.convertMonthlyRentCurrencyUseCase)
    var convertMonthlyRentCurrencyUseCase
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var userType: UserType?
        var appLanguage: AppLanguage
        var recentListings: [Listing] = []
        var items: [ListingItemModel]
        var isLoading = false
        var isLoaded: Bool
        var favoriteUpdatingIDs: Set<String> = []
        var errorMessage: String?
        var exchangeRate: KRWToUSDExchangeRate?
        var isExchangeRateLoading = false
        
        init(
            userType: UserType? = nil,
            appLanguage: AppLanguage = .english,
            items: [ListingItemModel] = []
        ) {
            self.userType = userType
            self.appLanguage = appLanguage
            self.items = items
            self.isLoaded = !items.isEmpty
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case cancelEffects
        case recentListingsResponse(Result<[Listing], DataError>)
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, Error>)
        case likeButtonTapped(id: String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return loadContent(state: &state)
                
            case .cancelEffects:
                return .merge(
                    .cancel(id: EffectID.recentListings),
                    .cancel(id: EffectID.exchangeRate),
                    .cancel(id: EffectID.favorite)
                )
                
            case let .recentListingsResponse(.success(listings)):
                state.recentListings = listings
                state.items = listings.map {
                    makeItem(listing: $0, state: state)
                }
                state.isLoading = false
                state.isLoaded = true
                state.errorMessage = nil
                return .none
                
            case let .recentListingsResponse(.failure(error)):
                state.isLoading = false
                state.isLoaded = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .exchangeRateResponse(.success(exchangeRate)):
                state.exchangeRate = exchangeRate
                state.isExchangeRateLoading = false
                synchronizeExchangeRate(exchangeRate, state: &state)
                return .none
                
            case .exchangeRateResponse(.failure):
                state.isExchangeRateLoading = false
                return .none
                
            case let .likeButtonTapped(id):
                return updateFavorite(id: id, state: &state)
                
            case let .favoriteStatusResponse(listingID, .success(status)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.errorMessage = nil
                state.synchronizeFavoriteStatus(status, for: listingID)
                return .none
                
            case let .favoriteStatusResponse(listingID, .failure(error)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
    
    // MARK: - Method
    
    func loadContent(state: inout State) -> Effect<Action> {
        var effects: [Effect<Action>] = []
        
        if state.canUseFavoriteFeatures, !state.isLoading, !state.isLoaded {
            state.isLoading = true
            state.errorMessage = nil
            effects.append(
                .run { [listingClient] send in
                    do {
                        let listings = try await listingClient.fetchRecentListings()
                        await send(.recentListingsResponse(.success(listings)))
                    } catch {
                        await send(.recentListingsResponse(.failure(.from(error))))
                    }
                }
                    .cancellable(id: EffectID.recentListings, cancelInFlight: true)
            )
        }
        
        if state.exchangeRate == nil, !state.isExchangeRateLoading {
            state.isExchangeRateLoading = true
            effects.append(
                .run { [fetchKRWToUSDExchangeRateUseCase] send in
                    do {
                        let exchangeRate = try await fetchKRWToUSDExchangeRateUseCase.execute()
                        await send(.exchangeRateResponse(.success(exchangeRate)))
                    } catch {
                        await send(.exchangeRateResponse(.failure(error)))
                    }
                }
                    .cancellable(id: EffectID.exchangeRate, cancelInFlight: true)
            )
        }
        
        return .merge(effects)
    }
    
    func updateFavorite(id: String, state: inout State) -> Effect<Action> {
        guard state.canUseFavoriteFeatures,
              let item = state.items.first(where: { $0.id == id }),
              !state.favoriteUpdatingIDs.contains(id)
        else { return .none }
        
        state.favoriteUpdatingIDs.insert(id)
        state.errorMessage = nil
        
        return .run { [listingClient, isLiked = item.isLiked] send in
            do {
                let status = try await isLiked
                ? listingClient.removeFavorite(id)
                : listingClient.addFavorite(id)
                await send(.favoriteStatusResponse(listingID: id, .success(status)))
            } catch {
                await send(.favoriteStatusResponse(listingID: id, .failure(.from(error))))
            }
        }
        .cancellable(id: EffectID.favorite)
    }
    
    func synchronizeExchangeRate(_ exchangeRate: KRWToUSDExchangeRate, state: inout State) {
        guard !state.recentListings.isEmpty else { return }
        
        let currentItems = state.items
        state.items = state.recentListings.map { listing in
            var item = makeItem(listing: listing, state: state, exchangeRate: exchangeRate)
            if let currentItem = currentItems.first(where: { $0.id == item.id }) {
                item.isLiked = currentItem.isLiked
                item.favoriteCount = currentItem.favoriteCount
            }
            return item
        }
    }
    
    func makeItem(listing: Listing, state: State, exchangeRate: KRWToUSDExchangeRate? = nil) -> ListingItemModel {
        ListingItemModel(listing: listing, exchangeRate: exchangeRate ?? state.exchangeRate,
                         convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase, language: state.appLanguage)
    }
}

extension HomeRecentlyViewedFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
    
    mutating func synchronizeFavoriteStatus(_ status: ListingFavoriteStatus, for listingID: String) {
        guard let index = items.firstIndex(where: { $0.id == listingID }) else { return }
        items[index].isLiked = status.isFavorited
        items[index].favoriteCount = status.favoriteCount
    }
}
