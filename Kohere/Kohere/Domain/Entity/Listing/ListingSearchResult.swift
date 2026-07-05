//
//  ListingSearchResult.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

struct ListingSearchPage: Equatable {
    let content: [ListingSearchListing]
    let page: ListingSearchPageInfo?
}

struct ListingSearchPageInfo: Equatable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}

struct ListingSearchListing: Equatable, Identifiable {
    var id: String { roomOfferID.isEmpty ? listingID : roomOfferID }

    let listingID: String
    let roomOfferID: String
    let roomOfferName: String
    let title: String
    let type: String
    let monthlyRent: Int?
    let deposit: Int?
    let maintenanceFee: Int?
    let availableCount: Int?
    let thumbnailURL: String?
    let coordinate: MapCoordinate?
    let address: String?
    let conditions: [RoomCondition]
    let distanceMeters: Double?
}
