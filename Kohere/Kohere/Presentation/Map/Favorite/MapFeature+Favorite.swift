//
//  MapFeature+Favorite.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

extension MapFeature {
    func startFavoriteUpdateEffect(
        listingID: String,
        state: inout State
    ) -> Effect<Action> {
        guard state.canUseFavoriteFeatures,
              let item = state.listings.first(where: { $0.listingID == listingID })
                ?? state.selectedListingItem.flatMap({ $0.listingID == listingID ? $0 : nil }),
              !state.favoriteUpdatingIDs.contains(listingID)
        else { return .none }

        state.favoriteUpdatingIDs.insert(listingID)
        state.favoriteErrorMessage = nil

        return .run { [listingClient, isLiked = item.isLiked] send in
            do {
                let status: ListingFavoriteStatus
                if isLiked {
                    status = try await listingClient.removeFavorite(listingID)
                } else {
                    status = try await listingClient.addFavorite(listingID)
                }
                await send(.favoriteStatusResponse(listingID: listingID, .success(status)))
            } catch {
                await send(.favoriteStatusResponse(listingID: listingID, .failure(.from(error))))
            }
        }
    }

    func handleFavoriteStatusResponse(
        listingID: String,
        result: Result<ListingFavoriteStatus, DataError>,
        state: inout State
    ) -> Effect<Action> {
        state.favoriteUpdatingIDs.remove(listingID)

        switch result {
        case let .success(status):
            state.favoriteErrorMessage = nil
            applyFavoriteStatus(status, for: listingID, to: &state)

        case let .failure(error):
            state.favoriteErrorMessage = error.localizedDescription
        }

        return .none
    }

    func applyFavoriteStatus(
        _ status: ListingFavoriteStatus,
        for listingID: String,
        to state: inout State
    ) {
        state.synchronizeFavoriteStatus(status, for: listingID)
    }
}

extension MapFeature.State {
    mutating func synchronizeFavoriteStatus(
        _ status: ListingFavoriteStatus,
        for listingID: String
    ) {
        // 카드 목록(listings)은 이 값을 반영해 계산되므로 따로 갱신하지 않는다.
        favoriteStatusesByListingID[listingID] = status
    }
}
