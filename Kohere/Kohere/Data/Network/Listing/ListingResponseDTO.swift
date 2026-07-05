//
//  ListingResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

struct ListingListResponseDTO: Decodable {
    let content: [ListingListItemResponseDTO]?
    let page: ListingPageResponseDTO?
}

struct ListingListItemResponseDTO: Decodable {
    let listingId: String?
    let roomOfferId: String?
    let roomOfferName: String?
    let title: String?
    let type: String?
    let monthlyRent: Int?
    let deposit: Int?
    let maintenanceFee: Int?
    let availableCount: Int?
    let thumbnailUrl: String?
    let lat: Double?
    let lng: Double?
    let address: String?
    let conditions: [String]?
    let distanceMeters: Double?
}

struct ListingPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
    let last: Bool?
}
