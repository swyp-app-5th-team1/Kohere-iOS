//
//  ListingDetail.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

struct ListingDetail: Equatable, Identifiable {
    nonisolated var id: String { listingID }

    let listingID: String
    let title: String
    let type: String
    let status: String
    let rentalType: String
    let refundPolicy: ListingDetailRefundPolicy?
    let contract: ListingDetailContract?
    let genderPolicy: String?
    let coordinate: MapCoordinate?
    let address: ListingDetailAddress?
    let nearestTransit: ListingDetailNearestTransit?
    let nearbyUniversityCodes: [String]
    let building: ListingDetailBuilding?
    let propertyPolicies: ListingDetailPropertyPolicies?
    let facilities: ListingDetailFacilities?
    let conditionCodes: [String]
    let conditions: [RoomCondition]
    let roomOffers: [ListingDetailRoomOffer]
    let descriptions: ListingDetailDescriptions?
    let imageURLs: [String]
    let isFavorited: Bool
    let favoriteCount: Int
    let createdAt: String?
    let updatedAt: String?
}

struct ListingDetailRefundPolicy: Equatable {
    let code: String
    let description: String?
}

struct ListingDetailContract: Equatable {
    let minStayMonths: Int?
    let maxStayMonths: Int?
}

struct ListingDetailAddress: Equatable {
    let city: String?
    let district: String?
    let fullAddress: String?
    let detail: String?
}

struct ListingDetailNearestTransit: Equatable {
    let type: String?
    let name: String
    let walkMinutes: Int?
    let nearbyPlacesDescription: String?
}

struct ListingDetailBuilding: Equatable {
    let type: String?
    let usedFloorMin: Int?
    let usedFloorMax: Int?
    let totalFloors: Int?
    let parkingAvailable: Bool?
    let elevatorAvailable: Bool?
}

struct ListingDetailPropertyPolicies: Equatable {
    let arcRequired: Bool?
    let residentRegistrationAvailable: Bool?
    let studySuitable: Bool?
    let mealsProvided: Bool?
    let englishAvailable: Bool?
}

struct ListingDetailFacilities: Equatable {
    let heatingSystem: [String]
    let kitchen: [String]
    let laundry: [String]
    let livingAmenities: [String]
    let securityFeatures: [String]
    let commonSpaces: [ListingDetailCommonSpace]
    let providedSupplies: [String]
}

struct ListingDetailCommonSpace: Equatable {
    let type: String
    let count: Int?
}

struct ListingDetailRoomOffer: Equatable, Identifiable {
    let id: String
    let name: String
    let status: String?
    let pricing: ListingDetailRoomPricing?
    let inventory: ListingDetailRoomInventory?
    let filterTagCodes: [String]
    let filterTags: [RoomCondition]
    let roomImageURLs: [String]
}

struct ListingDetailRoomPricing: Equatable {
    let monthlyRent: Int?
    let deposit: Int?
    let maintenanceFee: Int?
    let currency: String?
}

struct ListingDetailRoomInventory: Equatable {
    let totalCount: Int?
    let availableCount: Int?
    let nextAvailableFrom: String?
}

struct ListingDetailDescriptions: Equatable {
    let korean: String?
    let english: String?
    let extraNotes: String?
}
