//
//  ListingItem.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import Foundation

struct ListingItem: Equatable, Identifiable {
    let id: Int
    let formattedPrice: String
    let formattedUsdPrice: String
    let detailsDescription: String
    let locationDescription: String
    let typeTag: String
    let period: String
    var isLiked: Bool
}

extension ListingItem {
    init(from entity: Listing) {
        self.id = entity.id
        self.isLiked = entity.isLiked
        self.formattedPrice = "₩\(entity.minPriceKRW / 1000)~\(entity.maxPriceKRW / 1000)K/mo"
        self.formattedUsdPrice = "≈$\(entity.priceUSD)/mo"
        self.detailsDescription = "Dep. ₩\(entity.deposit / 1000)K · Maint. ₩\(entity.maintenanceFee / 1000)K"
        self.locationDescription = "\(entity.distanceToStationMinutes)-min walk \(entity.stationName) Sta."
        self.typeTag = entity.accommodationType.lowercased().capitalized
        self.period = "\(entity.minStayMonths) mo~"
    }
}

extension ListingItem {
    static let mockList: [ListingItem] = [
        ListingItem(
            id: 1,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$286/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        ),
        ListingItem(
            id: 2,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$286/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        ),
        ListingItem(
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
