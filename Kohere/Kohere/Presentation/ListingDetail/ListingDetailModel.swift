//
//  ListingDetailModel.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import Foundation

struct ListingDetailModel: Equatable, Identifiable {
    let id: String
    var overview: ListingDetailOverviewModel
    let tabs: [String]
    let roomOffers: [ListingRoomOfferModel]
    let priceInfo: [ListingDetailInfoRowModel]
    let propertyInfo: [ListingDetailInfoRowModel]
    let propertyFeatures: [String]
    let buildingInfo: [ListingDetailInfoRowModel]
    let facilityInfo: [ListingDetailInfoRowModel]
    let locationInfo: ListingLocationInfoModel
}

struct ListingDetailOverviewModel: Equatable, Identifiable {
    let id: String
    let title: String
    let typeTag: String
    let imageURLs: [String]
    let monthlyRentText: String
    let convertedMonthlyRentText: String
    let depositText: String
    let maintenanceFeeText: String
    let transitText: String
    let imageCountText: String
    let reviewCount: Int
    var isLiked: Bool
    var favoriteCount: Int?

    init(
        id: String,
        title: String,
        typeTag: String,
        imageURLs: [String] = [],
        monthlyRentText: String,
        convertedMonthlyRentText: String,
        depositText: String,
        maintenanceFeeText: String,
        transitText: String,
        imageCountText: String,
        reviewCount: Int,
        isLiked: Bool,
        favoriteCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.typeTag = typeTag
        self.imageURLs = imageURLs
        self.monthlyRentText = monthlyRentText
        self.convertedMonthlyRentText = convertedMonthlyRentText
        self.depositText = depositText
        self.maintenanceFeeText = maintenanceFeeText
        self.transitText = transitText
        self.imageCountText = imageCountText
        self.reviewCount = reviewCount
        self.isLiked = isLiked
        self.favoriteCount = favoriteCount
    }
}

struct ListingRoomOfferModel: Equatable, Identifiable {
    let id: String
    let name: String
    let imageURLs: [String]
    let pricingText: String
    let tags: [String]

    init(
        id: String,
        name: String,
        imageURLs: [String] = [],
        pricingText: String,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.imageURLs = imageURLs
        self.pricingText = pricingText
        self.tags = tags
    }
}

struct ListingDetailInfoRowModel: Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
}

struct ListingLocationInfoModel: Equatable {
    let sectionTitle: String
    let addressText: String
    let transits: [ListingTransitInfoModel]
    let coordinate: MapCoordinate?
    let nearbyPlacesTitle: String
    let nearbyPlacesText: String
}

struct ListingTransitInfoModel: Equatable, Identifiable {
    let id: String
    let lineText: String
    let lineColorName: String
    let description: String
}

extension ListingDetailModel {
    static func tabs(language: AppLanguage) -> [String] {
        [
            language.localized("listingDetail.tab.roomOffers"),
            language.localized("listingDetail.tab.price"),
            language.localized("listingDetail.tab.property"),
            language.localized("listingDetail.tab.building"),
            language.localized("listingDetail.tab.facility"),
            language.localized("listingDetail.tab.location"),
            language.localized("listingDetail.tab.review")
        ]
    }
}
