//
//  Booking.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

nonisolated struct BookingPage: Equatable {
    let content: [BookingSummary]
    let page: PageInfo?
}

nonisolated struct BookingSummary: Equatable, Identifiable {
    let bookingID: Int
    let listingID: String
    let title: String
    let thumbnailURL: URL?
    let roomOfferID: String
    let moveInDate: Date?
    let contractPeriod: Int
    let status: String
    let createdAt: Date?
    
    var id: Int { bookingID }
}

nonisolated struct BookingDetail: Equatable, Identifiable {
    let bookingID: Int
    let status: String
    let listingID: String
    let roomOfferID: String
    let title: String
    let thumbnailURL: URL?
    let address: String
    let roomOfferName: String
    let createdAt: Date?
    let moveInDate: Date?
    let contractPeriod: Int
    let applicantName: String
    let applicantGender: String
    let applicantCountry: String
    let applicantCountryName: String
    let applicantEmail: String
    let tenantName: String
    let deposit: Int
    let totalAmount: Int
    
    var id: Int { bookingID }
}
