//
//  ListingDetailFeature.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ListingDetailFeature {
    @Dependency(\.listingClient)
    var listingClient

    @ObservableState
    struct State: Equatable {
        var detail: ListingDetailModel
        var userType: UserType?
        var isFavoriteUpdating = false
        var errorMessage: String?

        init(
            listingID: String,
            userType: UserType? = nil
        ) {
            self.detail = ListingDetailModel.mock(id: listingID)
            self.userType = userType
        }
    }

    enum Action: Equatable {
        case backButtonTapped
        case likeButtonTapped
        case favoriteStatusResponse(Result<ListingFavoriteStatus, DataError>)
        case shareButtonTapped
        case contactButtonTapped
        case applyButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .likeButtonTapped:
                guard state.canUseFavoriteFeatures,
                      !state.isFavoriteUpdating
                else { return .none }

                state.isFavoriteUpdating = true
                state.errorMessage = nil

                return .run { [listingClient, listingID = state.detail.id, isLiked = state.detail.overview.isLiked] send in
                    do {
                        let status: ListingFavoriteStatus
                        if isLiked {
                            status = try await listingClient.removeFavorite(listingID)
                        } else {
                            status = try await listingClient.addFavorite(listingID)
                        }
                        await send(.favoriteStatusResponse(.success(status)))
                    } catch {
                        await send(.favoriteStatusResponse(.failure(.from(error))))
                    }
                }

            case let .favoriteStatusResponse(.success(status)):
                state.detail.overview.isLiked = status.isFavorited
                state.detail.overview.favoriteCount = status.favoriteCount
                state.isFavoriteUpdating = false
                state.errorMessage = nil
                return .none

            case let .favoriteStatusResponse(.failure(error)):
                state.isFavoriteUpdating = false
                state.errorMessage = error.localizedDescription
                return .none

            case .backButtonTapped, .shareButtonTapped, .contactButtonTapped, .applyButtonTapped:
                return .none
            }
        }
    }
}

extension ListingDetailFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}
