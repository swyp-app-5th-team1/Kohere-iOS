//
//  SavedListingsFeature.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SavedListingsFeature {
    @Dependency(\.listingClient)
    var listingClient
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var items: [ListingItemModel] = []
        var isLoading: Bool = false
        var favoriteUpdatingIDs: Set<String> = []
        var errorMessage: String?
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case onAppear
        case favoriteListingsResponse(Result<ListingSearchPage, DataError>)
        case cardTapped(id: String)
        case likeButtonTapped(id: String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)
        case backButtonTapped
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                return .run { [listingClient] send in
                    do {
                        let page = try await listingClient.fetchFavoriteListings(0, 20)
                        await send(.favoriteListingsResponse(.success(page)))
                    } catch {
                        await send(.favoriteListingsResponse(.failure(.from(error))))
                    }
                }

            case let .favoriteListingsResponse(.success(page)):
                state.items = page.content.map(ListingItemModel.init(listing:))
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .favoriteListingsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .cardTapped(id):
                // TODO: 해당 매물 상세 정보 뷰로 네비게이션
                print("선택 매물\(id)") // never used 방지
                return .none
                
            case let .likeButtonTapped(id):
                guard let item = state.items.first(where: { $0.id == id }),
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
                
            case .backButtonTapped:
                return .none
            }
        }
    }
}
