//
//  RootFeature+FavoriteSync.swift
//  Kohere
//
//  Created by Codex on 7/12/26.
//

extension RootFeature {
    func synchronizeFavoriteStatus(
        _ status: ListingFavoriteStatus,
        for listingID: String,
        state: inout State
    ) {
        state.home.synchronizeFavoriteStatus(status, for: listingID)
        state.map.synchronizeFavoriteStatus(status, for: listingID)
    }
}
