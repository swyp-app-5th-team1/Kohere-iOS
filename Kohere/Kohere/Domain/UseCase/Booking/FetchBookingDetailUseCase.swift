//
//  FetchBookingDetailUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct FetchBookingDetailUseCase {
    var execute: (_ bookingID: Int) async throws -> BookingDetail
}

extension FetchBookingDetailUseCase: DependencyKey {
    static let liveValue: FetchBookingDetailUseCase = {
        @Dependency(\.bookingClient)
        var bookingClient
        
        return FetchBookingDetailUseCase { bookingID in
            try await bookingClient.fetchBookingDetail(bookingID)
        }
    }()
}

extension DependencyValues {
    var fetchBookingDetailUseCase: FetchBookingDetailUseCase {
        get { self[FetchBookingDetailUseCase.self] }
        set { self[FetchBookingDetailUseCase.self] = newValue }
    }
}
