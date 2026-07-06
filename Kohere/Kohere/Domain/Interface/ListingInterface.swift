//
//  ListingInterface.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

protocol ListingInterface {
    func fetchListings(input: ListingSearchInput) async throws -> ListingSearchPage
}

struct ListingClient: Sendable {
    var fetchListings: @Sendable (_ input: ListingSearchInput) async throws -> ListingSearchPage
}

extension ListingClient {
    init(repository: any ListingInterface) {
        self.init(
            fetchListings: { input in
                try await repository.fetchListings(input: input)
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
