//
//  UpdateListingFavoriteUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct UpdateListingFavoriteUseCase: Sendable {
    var execute: @Sendable (_ listingID: String, _ isCurrentlyFavorited: Bool) async throws -> ListingFavoriteStatus
}

extension UpdateListingFavoriteUseCase: DependencyKey {
    static let liveValue: UpdateListingFavoriteUseCase = {
        @Dependency(\.listingClient)
        var listingClient

        return UpdateListingFavoriteUseCase { listingID, isCurrentlyFavorited in
            if isCurrentlyFavorited {
                try await listingClient.removeFavorite(listingID)
            } else {
                try await listingClient.addFavorite(listingID)
            }
        }
    }()
}

extension DependencyValues {
    var updateListingFavoriteUseCase: UpdateListingFavoriteUseCase {
        get { self[UpdateListingFavoriteUseCase.self] }
        set { self[UpdateListingFavoriteUseCase.self] = newValue }
    }
}
