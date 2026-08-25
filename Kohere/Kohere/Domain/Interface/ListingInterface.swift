//
//  ListingInterface.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

protocol ListingInterface {
    func fetchListings(input: ListingSearchInput) async throws -> ListingSearchPage
    func fetchMapMarkers(input: ListingSearchInput) async throws -> [ListingMapMarker]
    func fetchDetail(listingID: String) async throws -> ListingDetail
    func fetchFavoriteListings(page: Int, size: Int) async throws -> ListingSearchPage
    func fetchRecentListings() async throws -> [Listing]
    func addFavorite(listingID: String) async throws -> ListingFavoriteStatus
    func removeFavorite(listingID: String) async throws -> ListingFavoriteStatus
    func createBooking(listingID: String, input: ListingBookingCreateInput) async throws -> ListingBooking
}

struct ListingClient: Sendable {
    var fetchListings: @Sendable (_ input: ListingSearchInput) async throws -> ListingSearchPage
    var fetchMapMarkers: @Sendable (_ input: ListingSearchInput) async throws -> [ListingMapMarker] = { _ in [] }
    var fetchDetail: @Sendable (_ listingID: String) async throws -> ListingDetail
    var fetchFavoriteListings: @Sendable (_ page: Int, _ size: Int) async throws -> ListingSearchPage
    var fetchRecentListings: @Sendable () async throws -> [Listing]
    var addFavorite: @Sendable (_ listingID: String) async throws -> ListingFavoriteStatus
    var removeFavorite: @Sendable (_ listingID: String) async throws -> ListingFavoriteStatus
    var createBooking: @Sendable (_ listingID: String, _ input: ListingBookingCreateInput) async throws -> ListingBooking
}

extension ListingClient {
    init(repository: any ListingInterface) {
        self.init(
            fetchListings: { input in
                try await repository.fetchListings(input: input)
            },
            fetchMapMarkers: { input in
                try await repository.fetchMapMarkers(input: input)
            },
            fetchDetail: { listingID in
                try await repository.fetchDetail(listingID: listingID)
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
            },
            createBooking: { listingID, input in
                try await repository.createBooking(listingID: listingID, input: input)
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
