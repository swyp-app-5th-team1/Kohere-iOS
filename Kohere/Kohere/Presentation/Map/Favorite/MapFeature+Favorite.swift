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
        rebuildListingItems(to: &state)
    }

    func applyFavoriteStatusOverrides(
        to listings: inout [ListingItemModel],
        statusByID: [String: ListingFavoriteStatus]
    ) {
        for index in listings.indices {
            guard let status = statusByID[listings[index].listingID] else { continue }
            listings[index].isLiked = status.isFavorited
            listings[index].favoriteCount = status.favoriteCount
        }
    }
}

extension MapFeature.State {
    mutating func synchronizeFavoriteStatus(
        _ status: ListingFavoriteStatus,
        for listingID: String
    ) {
        favoriteStatusesByListingID[listingID] = status

        guard let index = listings.firstIndex(where: { $0.listingID == listingID }) else {
            return
        }

        listings[index].isLiked = status.isFavorited
        listings[index].favoriteCount = status.favoriteCount
    }
}
