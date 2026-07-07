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
    let contract: ListingContractResponseDTO?
    let location: ListingLocationResponseDTO?
    let address: ListingAddressResponseDTO?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let conditions: [String]?
    let roomOffers: [ListingRoomOfferResponseDTO]?
    let imageUrls: [String]?
    let distanceMeters: Double?
    let favorited: Bool?
    let favoriteCount: Int?
}

struct ListingNearestTransitResponseDTO: Decodable {
    let type: String?
    let name: String?
    let walkMinutes: Int?
}

struct ListingLocationResponseDTO: Decodable {
    let lat: Double?
    let lng: Double?
}

struct ListingAddressResponseDTO: Decodable {
    let fullAddress: String?
}

struct ListingContractResponseDTO: Decodable {
    let minStayMonths: Int?
    let maxStayMonths: Int?
}

struct ListingRoomOfferResponseDTO: Decodable {
    let pricing: ListingRoomPricingResponseDTO?
}

struct ListingRoomPricingResponseDTO: Decodable {
    let monthlyRent: Int?
    let deposit: Int?
    let maintenanceFee: Int?
}

struct ListingPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
    let last: Bool?
}
