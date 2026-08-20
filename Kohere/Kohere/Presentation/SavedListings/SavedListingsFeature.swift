//
//  SavedListingsFeature.swift
//  Kohere
//
//  Created by soomin on 6/24/26.
//

import ComposableArchitecture
import Foundation

enum SavedListingsDelegate: Equatable {
    case listingDetailRequested(String)
}

@Reducer
struct SavedListingsFeature {
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
        var appLanguage: AppLanguage = .english
        var listings: [Listing] = []
        var items: [ListingItemModel] = []
        var isLoading: Bool = false
        var krwToUSDExchangeRate: KRWToUSDExchangeRate?
        var isExchangeRateLoading = false
        var favoriteUpdatingIDs: Set<String> = []
        var errorMessage: String?
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case onAppear
        case favoriteListingsResponse(Result<ListingSearchPage, DataError>)
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, CurrencyError>)
        case cardTapped(id: String)
        case likeButtonTapped(id: String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)
        case backButtonTapped
        case delegate(SavedListingsDelegate)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                var effects: [Effect<Action>] = []

                if state.canUseFavoriteFeatures, !state.isLoading {
                    state.isLoading = true
                    state.errorMessage = nil
                    effects.append(
                        .run { [listingClient] send in
                            do {
                                // TODO: 고도화 때 페이지네이션 처리
                                let page = try await listingClient.fetchFavoriteListings(0, 30)
                                await send(.favoriteListingsResponse(.success(page)))
                            } catch {
                                await send(.favoriteListingsResponse(.failure(.from(error))))
                            }
                        }
                    )
                }

                if state.krwToUSDExchangeRate == nil, !state.isExchangeRateLoading {
                    state.isExchangeRateLoading = true
                    effects.append(
                        .run { [fetchKRWToUSDExchangeRateUseCase] send in
                            do {
                                let rate = try await fetchKRWToUSDExchangeRateUseCase.execute()
                                await send(.exchangeRateResponse(.success(rate)))
                            } catch {
                                await send(.exchangeRateResponse(.failure(.exchangeRateUnavailable)))
                            }
                        }
                    )
                }

                return .merge(effects)

            case let .favoriteListingsResponse(.success(page)):
                state.listings = page.content
                state.items = listingItems(from: page.content, state: state)
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .favoriteListingsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .exchangeRateResponse(.success(rate)):
                state.krwToUSDExchangeRate = rate
                state.isExchangeRateLoading = false
                state.items = listingItems(from: state.listings, state: state)
                return .none

            case .exchangeRateResponse(.failure):
                state.isExchangeRateLoading = false
                return .none
                
            case let .cardTapped(id):
                return .send(.delegate(.listingDetailRequested(id)))
                
            case let .likeButtonTapped(id):
                guard state.canUseFavoriteFeatures,
                      let item = state.items.first(where: { $0.id == id }),
                      !state.favoriteUpdatingIDs.contains(id)
                else { return .none }

                state.favoriteUpdatingIDs.insert(id)
                state.errorMessage = nil

                return .run { [listingClient, isLiked = item.isLiked] send in
                    do {
                        let status: ListingFavoriteStatus
                        if isLiked {
                            status = try await listingClient.removeFavorite(id)
                        } else {
                            status = try await listingClient.addFavorite(id)
                        }
                        await send(.favoriteStatusResponse(listingID: id, .success(status)))
                    } catch {
                        await send(.favoriteStatusResponse(listingID: id, .failure(.from(error))))
                    }
                }

            case let .favoriteStatusResponse(listingID, .success(status)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.errorMessage = nil

                if status.isFavorited {
                    if let index = state.items.firstIndex(where: { $0.id == listingID }) {
                        state.items[index].isLiked = true
                        state.items[index].favoriteCount = status.favoriteCount
                    }
                } else {
                    state.items.removeAll { $0.id == listingID }
                }
                return .none

            case let .favoriteStatusResponse(listingID, .failure(error)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.errorMessage = error.localizedDescription
                return .none
                
            case .backButtonTapped, .delegate:
                return .none
            }
        }
    }

    private func listingItems(
        from listings: [Listing],
        state: State
    ) -> [ListingItemModel] {
        listings.map {
            ListingItemModel(
                listing: $0,
                exchangeRate: state.krwToUSDExchangeRate,
                convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
                language: state.appLanguage
            )
        }
    }
}

extension SavedListingsFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}
