//
//  Listing.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

struct Listing: Equatable, Identifiable {
    nonisolated var id: String { listingID }

    let listingID: String
    let title: String
    let type: String
    let minMonthlyRent: Int?
    let maxMonthlyRent: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let minMaintenanceFee: Int?
    let maxMaintenanceFee: Int?
    let minStayMonths: Int?
    let maxStayMonths: Int?
    let thumbnailURL: String?
    let coordinate: MapCoordinate?
    let address: String?
    let nearestTransit: ListingNearestTransit?
    let conditions: [RoomCondition]
    let distanceMeters: Double?
    let isFavorited: Bool
}

struct ListingNearestTransit: Equatable {
    let type: String
    let name: String
    let walkMinutes: Int?
}
