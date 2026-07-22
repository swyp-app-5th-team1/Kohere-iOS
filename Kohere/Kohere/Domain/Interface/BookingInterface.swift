//
//  BookingInterface.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

protocol BookingInterface {
    func fetchBookings(page: Int, size: Int) async throws -> BookingPage
    func fetchBookingDetail(bookingID: Int) async throws -> BookingDetail
    func mutateBooking(_ mutation: BookingMutation, bookingID: Int) async throws
}

enum BookingMutation: Equatable, Sendable {
    case report
    case block
    case delete
}

struct BookingClient: Sendable {
    var fetchBookings: @Sendable (_ page: Int, _ size: Int) async throws -> BookingPage
    var fetchBookingDetail: @Sendable (_ bookingID: Int) async throws -> BookingDetail
    var mutateBooking: @Sendable (_ mutation: BookingMutation, _ bookingID: Int) async throws -> Void
}

extension BookingClient {
    init(repository: any BookingInterface) {
        self.init(
            fetchBookings: { page, size in
                try await repository.fetchBookings(page: page, size: size)
            },
            fetchBookingDetail: { bookingID in
                try await repository.fetchBookingDetail(bookingID: bookingID)
            },
            mutateBooking: { mutation, bookingID in
                try await repository.mutateBooking(mutation, bookingID: bookingID)
            }
        )
    }
}

extension DependencyValues {
    var bookingClient: BookingClient {
        get { self[BookingClient.self] }
        set { self[BookingClient.self] = newValue }
    }
}
