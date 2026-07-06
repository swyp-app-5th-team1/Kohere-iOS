//
//  FetchListingsUseCase.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

struct FetchListingsUseCase {
    var execute: (_ input: ListingSearchInput) async throws -> ListingSearchPage
}

extension FetchListingsUseCase: DependencyKey {
    static let liveValue: FetchListingsUseCase = {
        @Dependency(\.listingClient)
        var listingClient

        return FetchListingsUseCase { input in
            try await listingClient.fetchListings(input)
        }
    }()
}

extension DependencyValues {
    var fetchListingsUseCase: FetchListingsUseCase {
        get { self[FetchListingsUseCase.self] }
        set { self[FetchListingsUseCase.self] = newValue }
    }
}
