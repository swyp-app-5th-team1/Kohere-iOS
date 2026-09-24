//
//  FetchRecentListingsUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct FetchRecentListingsUseCase: Sendable {
    var execute: @Sendable () async throws -> [Listing]
}

extension FetchRecentListingsUseCase: DependencyKey {
    static let liveValue: FetchRecentListingsUseCase = {
        @Dependency(\.listingClient)
        var listingClient

        return FetchRecentListingsUseCase {
            try await listingClient.fetchRecentListings()
        }
    }()
}

extension DependencyValues {
    var fetchRecentListingsUseCase: FetchRecentListingsUseCase {
        get { self[FetchRecentListingsUseCase.self] }
        set { self[FetchRecentListingsUseCase.self] = newValue }
    }
}
