//
//  ListingResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

struct ListingListResponseDTO: Decodable {
    let content: [ListingItemV2ResponseDTO]?
    let page: PageResponseDTO?
}

struct ListingMapResponseDTO: Decodable {
    let total: Int?
    let markers: [ListingMapMarkerResponseDTO]?
}

struct ListingMapMarkerResponseDTO: Decodable {
    let listingId: String?
    let lat: Double?
    let lng: Double?
}

struct ListingFavoriteListResponseDTO: Decodable {
    let content: [ListingItemV2ResponseDTO]?
    let page: PageResponseDTO?
}

struct ListingRecentListResponseDTO: Decodable {
    let content: [ListingItemV2ResponseDTO]?
}

/// v2 공개·사용자 매물 목록 공용 항목.
/// 주소의 city/district가 code/label 객체이고, 계약 기간은 `roomOffers[].contract`에 실린다.
struct ListingItemV2ResponseDTO: Decodable {
    let listingId: String?
    let title: String?
    let type: ListingCodeLabelResponseDTO?
    let status: String?
    let rentalType: ListingCodeLabelResponseDTO?
    let genderPolicy: ListingCodeLabelResponseDTO?
    let location: ListingLocationResponseDTO?
    let address: ListingAddressV2ResponseDTO?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let roomOffers: [ListingRoomOfferV2ResponseDTO]?
    let imageUrls: [String]?
    let favorited: Bool?
    let favoriteCount: Int?
    /// 찜 목록 응답에만 존재
    let favoritedAt: String?
    /// 최근 본 목록 응답에만 존재
    let viewedAt: String?
    let createdAt: String?
    let updatedAt: String?
    let distanceMeters: Double?
}

struct ListingAddressV2ResponseDTO: Decodable {
    let city: ListingCodeLabelResponseDTO?
    let district: ListingCodeLabelResponseDTO?
    let fullAddress: String?
    let detail: String?
}

struct ListingRoomOfferV2ResponseDTO: Decodable {
    let roomOfferId: String?
    let name: String?
    let status: String?
    let contract: ListingContractResponseDTO?
    let pricing: ListingRoomPricingResponseDTO?
    let filterTags: [ListingCodeLabelResponseDTO]?
    let roomImageUrls: [String]?
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
    let type: ListingCodeLabelResponseDTO?
    let status: String?
    let rentalType: ListingCodeLabelResponseDTO?
    let refundPolicy: String?
    let genderPolicy: ListingCodeLabelResponseDTO?
    let location: ListingLocationResponseDTO?
    let address: ListingAddressV2ResponseDTO?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let nearbyUniversityCodes: [String]?
    let building: ListingBuildingResponseDTO?
    let arcRequired: ListingCodeLabelResponseDTO?
    let facilities: ListingFacilitiesResponseDTO?
    let conditions: [ListingCodeLabelResponseDTO]?
    let roomOffers: [ListingRoomOfferV2ResponseDTO]?
    let description: String?
    let extraNotes: String?
    let imageUrls: [String]?
    let favorited: Bool?
    let favoriteCount: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct ListingListItemResponseDTO: Decodable {
    let listingId: String?
    let title: String?
    let type: ListingCodeLabelResponseDTO?
    let contract: ListingContractResponseDTO?
    let location: ListingLocationResponseDTO?
    let address: ListingAddressResponseDTO?
    let nearestTransit: ListingNearestTransitResponseDTO?
    let roomOffers: [ListingRoomOfferResponseDTO]?
    let imageUrls: [String]?
    let distanceMeters: Double?
    let favorited: Bool?
    let favoriteCount: Int?
}

struct ListingNearestTransitResponseDTO: Decodable {
    let type: ListingCodeLabelResponseDTO?
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
    let type: ListingCodeLabelResponseDTO?
    let usedFloorMin: Int?
    let usedFloorMax: Int?
    let totalFloors: Int?
    let parkingAvailable: Bool?
    let elevatorAvailable: Bool?
}

struct ListingPropertyPoliciesResponseDTO: Decodable {
    let arcRequired: Bool?
    let residentRegistrationAvailable: Bool?
    let mealsProvided: Bool?
    let englishAvailable: Bool?
}

struct ListingFacilitiesResponseDTO: Decodable {
    let heatingSystem: [ListingCodeLabelResponseDTO]?
    let kitchen: [ListingCodeLabelResponseDTO]?
    let laundry: [ListingCodeLabelResponseDTO]?
    let livingAmenities: [ListingCodeLabelResponseDTO]?
    let securityFeatures: [ListingCodeLabelResponseDTO]?
    let commonSpaces: [ListingCodeLabelResponseDTO]?
    let providedSupplies: [ListingCodeLabelResponseDTO]?
}

struct ListingCommonSpaceResponseDTO: Decodable {
    let type: ListingCodeLabelResponseDTO?
    let count: Int?
}

struct ListingRoomOfferResponseDTO: Decodable {
    let roomOfferId: String?
    let name: String?
    let status: String?
    let pricing: ListingRoomPricingResponseDTO?
    let inventory: ListingRoomInventoryResponseDTO?
    let filterTags: [ListingCodeLabelResponseDTO]?
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

struct ListingCodeLabelResponseDTO: Decodable {
    let code: String
    let label: String
}
