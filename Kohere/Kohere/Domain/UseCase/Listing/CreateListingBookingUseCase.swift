//
//  CreateListingBookingUseCase.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture

struct CreateListingBookingUseCase {
    var execute: (_ listingID: String, _ input: ListingBookingCreateInput) async throws -> ListingBooking
}

extension CreateListingBookingUseCase: DependencyKey {
    static let liveValue: CreateListingBookingUseCase = {
        @Dependency(\.listingClient)
        var listingClient

        return CreateListingBookingUseCase { listingID, input in
            try await listingClient.createBooking(listingID, input)
        }
    }()
}

extension DependencyValues {
    var createListingBookingUseCase: CreateListingBookingUseCase {
        get { self[CreateListingBookingUseCase.self] }
        set { self[CreateListingBookingUseCase.self] = newValue }
    }
}
