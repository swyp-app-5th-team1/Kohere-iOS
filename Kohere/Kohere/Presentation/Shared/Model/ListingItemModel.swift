//
//  ListingItemModel.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import Foundation

struct ListingItemModel: Equatable, Identifiable {
    let id: String
    let title: String
    let formattedPrice: String
    let formattedUsdPrice: String
    let detailsDescription: String
    let locationDescription: String
    let typeTag: String
    let period: String
    var isLiked: Bool

    var listingID: String { id }

    init(
        id: String,
        title: String = "",
        formattedPrice: String,
        formattedUsdPrice: String,
        detailsDescription: String,
        locationDescription: String,
        typeTag: String,
        period: String,
        isLiked: Bool
    ) {
        self.id = id
        self.title = title
        self.formattedPrice = formattedPrice
        self.formattedUsdPrice = formattedUsdPrice
        self.detailsDescription = detailsDescription
        self.locationDescription = locationDescription
        self.typeTag = typeTag
        self.period = period
        self.isLiked = isLiked
    }

    init(
        id: Int,
        title: String = "",
        formattedPrice: String,
        formattedUsdPrice: String,
        detailsDescription: String,
        locationDescription: String,
        typeTag: String,
        period: String,
        isLiked: Bool
    ) {
        self.init(
            id: "\(id)",
            title: title,
            formattedPrice: formattedPrice,
            formattedUsdPrice: formattedUsdPrice,
            detailsDescription: detailsDescription,
            locationDescription: locationDescription,
            typeTag: typeTag,
            period: period,
            isLiked: isLiked
        )
    }
}

extension ListingItemModel {
    init(from entity: Listing) {
        self.id = "\(entity.id)"
        self.title = ""
        self.isLiked = entity.isLiked
        self.formattedPrice = "₩\(entity.minPriceKRW / 1000)~\(entity.maxPriceKRW / 1000)K/mo"
        self.formattedUsdPrice = "≈$\(entity.priceUSD)/mo"
        self.detailsDescription = "Dep. ₩\(entity.deposit / 1000)K · Maint. ₩\(entity.maintenanceFee / 1000)K"
        self.locationDescription = "\(entity.distanceToStationMinutes)-min walk \(entity.stationName) Sta."
        self.typeTag = entity.accommodationType.lowercased().capitalized
        self.period = "\(entity.minStayMonths) mo~"
    }
}

extension ListingItemModel {
    static let mockList: [ListingItemModel] = [
        ListingItemModel(
            id: 1,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$286/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        ),
        ListingItemModel(
            id: 2,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$286/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        ),
        ListingItemModel(
            id: 3,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$286/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        )
    ]
}
