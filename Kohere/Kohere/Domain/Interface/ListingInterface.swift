//
//  ListingInterface.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

protocol ListingInterface {
    func fetchListings(input: ListingSearchInput) async throws -> ListingSearchPage
    func fetchFavoriteListings(page: Int, size: Int) async throws -> ListingSearchPage
    func fetchRecentListings() async throws -> [Listing]
    func addFavorite(listingID: String) async throws -> ListingFavoriteStatus
    func removeFavorite(listingID: String) async throws -> ListingFavoriteStatus
}

struct ListingClient: Sendable {
    var fetchListings: @Sendable (_ input: ListingSearchInput) async throws -> ListingSearchPage
    var fetchFavoriteListings: @Sendable (_ page: Int, _ size: Int) async throws -> ListingSearchPage
    var fetchRecentListings: @Sendable () async throws -> [Listing]
    var addFavorite: @Sendable (_ listingID: String) async throws -> ListingFavoriteStatus
    var removeFavorite: @Sendable (_ listingID: String) async throws -> ListingFavoriteStatus
}

extension ListingClient {
    init(repository: any ListingInterface) {
        self.init(
            fetchListings: { input in
                try await repository.fetchListings(input: input)
            },
            fetchFavoriteListings: { page, size in
                try await repository.fetchFavoriteListings(page: page, size: size)
            },
            fetchRecentListings: {
                try await repository.fetchRecentListings()
            },
            addFavorite: { listingID in
                try await repository.addFavorite(listingID: listingID)
            },
            removeFavorite: { listingID in
                try await repository.removeFavorite(listingID: listingID)
            }
        )
    }
}

extension DependencyValues {
    var listingClient: ListingClient {
        get { self[ListingClient.self] }
        set { self[ListingClient.self] = newValue }
    }
}
