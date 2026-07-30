//
//  MutateBookingUseCase.swift
//  Kohere
//
//  Created by soomin on 7/22/26.
//

import ComposableArchitecture

struct MutateBookingUseCase {
    var execute: (_ mutation: BookingMutation, _ bookingID: Int) async throws -> Void
}

extension MutateBookingUseCase: DependencyKey {
    static let liveValue: MutateBookingUseCase = {
        @Dependency(\.bookingClient)
        var bookingClient

        return MutateBookingUseCase { mutation, bookingID in
            try await bookingClient.mutateBooking(mutation, bookingID)
        }
    }()
}

extension DependencyValues {
    var mutateBookingUseCase: MutateBookingUseCase {
        get { self[MutateBookingUseCase.self] }
        set { self[MutateBookingUseCase.self] = newValue }
    }
}
