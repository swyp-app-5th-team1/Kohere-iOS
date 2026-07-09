//
//  FetchListingDetailUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct FetchListingDetailUseCase {
    var execute: (_ listingID: String) async throws -> ListingDetail
}

extension FetchListingDetailUseCase: DependencyKey {
    static let liveValue: FetchListingDetailUseCase = {
        @Dependency(\.listingClient)
        var listingClient

        return FetchListingDetailUseCase { listingID in
            try await listingClient.fetchDetail(listingID)
        }
    }()
}

extension DependencyValues {
    var fetchListingDetailUseCase: FetchListingDetailUseCase {
        get { self[FetchListingDetailUseCase.self] }
        set { self[FetchListingDetailUseCase.self] = newValue }
    }
}
