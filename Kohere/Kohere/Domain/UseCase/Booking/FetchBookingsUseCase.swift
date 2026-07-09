//
//  FetchBookingsUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct FetchBookingsUseCase {
    var execute: (_ page: Int, _ size: Int) async throws -> BookingPage
}

extension FetchBookingsUseCase: DependencyKey {
    static let liveValue: FetchBookingsUseCase = {
        @Dependency(\.bookingClient)
        var bookingClient
        
        return FetchBookingsUseCase { page, size in
            try await bookingClient.fetchBookings(page, size)
        }
    }()
}

extension DependencyValues {
    var fetchBookingsUseCase: FetchBookingsUseCase {
        get { self[FetchBookingsUseCase.self] }
        set { self[FetchBookingsUseCase.self] = newValue }
    }
}
