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

struct ListingFavoriteListResponseDTO: Decodable {
    let content: [ListingListItemResponseDTO]?
    let page: ListingPageResponseDTO?
}

struct ListingRecentListResponseDTO: Decodable {
    let content: [ListingRecentListItemResponseDTO]?
}

struct ListingFavoriteStatusResponseDTO: Decodable {
    let favorited: Bool?
    let favoriteCount: Int?
}

struct ListingBookingResponseDTO: Decodable {
    let bookingId: Int?
    let status: String?
    let listingId: String?
    let roomOfferId: String?
    let moveInDate: String?
    let contractPeriod: Int?
    let createdAt: String?
}

struct ListingDetailResponseDTO: Decodable {
    let listingId: String?
    let title: String?
    let type: String?
    let status: String?
    let rentalType: String?
    let refundPolicy: ListingRefundPolicyResponseDTO?
    let contract: ListingContractResponseDTO?
    let genderPolicy: String?
    let location: ListingLocationResponseDTO?
    let address: ListingAddressResponseDTO?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let nearbyUniversityCodes: [String]?
    let building: ListingBuildingResponseDTO?
    let propertyPolicies: ListingPropertyPoliciesResponseDTO?
    let facilities: ListingFacilitiesResponseDTO?
    let conditions: [String]?
    let roomOffers: [ListingRoomOfferResponseDTO]?
    let descriptions: ListingDescriptionsResponseDTO?
    let imageUrls: [String]?
    let favorited: Bool?
    let favoriteCount: Int?
    let createdAt: String?
    let updatedAt: String?
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

struct ListingRecentListItemResponseDTO: Decodable {
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
    let viewedAt: String?
}

struct ListingNearestTransitResponseDTO: Decodable {
    let type: String?
    let name: String?
    let walkMinutes: Int?
    let nearbyPlacesDescription: String?
}

struct ListingLocationResponseDTO: Decodable {
    let lat: Double?
    let lng: Double?
}

struct ListingAddressResponseDTO: Decodable {
    let city: String?
    let district: String?
    let fullAddress: String?
    let detail: String?
}

struct ListingRefundPolicyResponseDTO: Decodable {
    let code: String?
    let description: String?
}

struct ListingContractResponseDTO: Decodable {
    let minStayMonths: Int?
    let maxStayMonths: Int?
}

struct ListingBuildingResponseDTO: Decodable {
    let type: String?
    let usedFloorMin: Int?
    let usedFloorMax: Int?
    let totalFloors: Int?
    let parkingAvailable: Bool?
    let elevatorAvailable: Bool?
}

struct ListingPropertyPoliciesResponseDTO: Decodable {
    let arcRequired: Bool?
    let residentRegistrationAvailable: Bool?
    let studySuitable: Bool?
    let mealsProvided: Bool?
    let englishAvailable: Bool?
}

struct ListingFacilitiesResponseDTO: Decodable {
    let heatingSystem: [String]?
    let kitchen: [String]?
    let laundry: [String]?
    let livingAmenities: [String]?
    let securityFeatures: [String]?
    let commonSpaces: [ListingCommonSpaceResponseDTO]?
    let providedSupplies: [String]?
}

struct ListingCommonSpaceResponseDTO: Decodable {
    let type: String?
    let count: Int?
}

struct ListingRoomOfferResponseDTO: Decodable {
    let roomOfferId: String?
    let name: String?
    let status: String?
    let pricing: ListingRoomPricingResponseDTO?
    let inventory: ListingRoomInventoryResponseDTO?
    let filterTags: [String]?
    let roomImageUrls: [String]?
}

struct ListingRoomPricingResponseDTO: Decodable {
    let monthlyRent: Int?
    let deposit: Int?
    let maintenanceFee: Int?
    let currency: String?
}

struct ListingRoomInventoryResponseDTO: Decodable {
    let totalCount: Int?
    let availableCount: Int?
    let nextAvailableFrom: String?
}

struct ListingDescriptionsResponseDTO: Decodable {
    let ko: String?
    let en: String?
    let extraNotes: String?
}

struct ListingPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
    let last: Bool?
}
