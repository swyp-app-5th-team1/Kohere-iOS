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
    let title: String?
    let type: String?
    let minMonthlyRent: Int?
    let maxMonthlyRent: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let minMaintenanceFee: Int?
    let maxMaintenanceFee: Int?
    let minStayMonths: Int?
    let maxStayMonths: Int?
    let thumbnailUrl: String?
    let lat: Double?
    let lng: Double?
    let address: String?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let conditions: [String]?
    let distanceMeters: Double?
    let favorited: Bool?
    let favoriteCount: Int?
}

struct ListingNearestTransitResponseDTO: Decodable {
    let type: String?
    let name: String?
    let walkMinutes: Int?
}

struct ListingPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
    let last: Bool?
}
