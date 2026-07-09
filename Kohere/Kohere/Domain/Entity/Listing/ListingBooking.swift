//
//  ListingBooking.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import Foundation

struct ListingBookingCreateInput: Equatable, Sendable {
    let roomOfferID: String
    let moveInDate: Date
    let contractPeriod: Int
}

struct ListingBooking: Equatable, Identifiable, Sendable {
    nonisolated var id: Int { bookingID }

    let bookingID: Int
    let status: String
    let listingID: String
    let roomOfferID: String
    let moveInDate: String
    let contractPeriod: Int
    let createdAt: String
}
