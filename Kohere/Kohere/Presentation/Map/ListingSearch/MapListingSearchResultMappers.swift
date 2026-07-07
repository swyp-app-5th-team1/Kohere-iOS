//
//  MapListingSearchResultMappers.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

extension ListingItemModel {
    nonisolated init(listing: Listing) {
        self.init(
            id: listing.id,
            title: listing.title,
            formattedPrice: Self.monthlyRentTitle(
                min: listing.minMonthlyRent,
                max: listing.maxMonthlyRent
            ),
            formattedUsdPrice: "",
            detailsDescription: Self.detailsTitle(
                minDeposit: listing.minDeposit,
                maxDeposit: listing.maxDeposit,
                minMaintenanceFee: listing.minMaintenanceFee,
                maxMaintenanceFee: listing.maxMaintenanceFee
            ),
            locationDescription: Self.locationTitle(from: listing),
            typeTag: Self.typeTitle(from: listing.type),
            period: Self.stayPeriodTitle(
                min: listing.minStayMonths,
                max: listing.maxStayMonths
            ),
            isLiked: listing.isFavorited,
            favoriteCount: listing.favoriteCount
        )
    }

    nonisolated private static func monthlyRentTitle(min: Int?, max: Int?) -> String {
        guard let rangeTitle = wonRangeTitle(min: min, max: max) else {
            return "월세 정보 없음"
        }

        return "월세 \(rangeTitle)"
    }

    nonisolated private static func detailsTitle(
        minDeposit: Int?,
        maxDeposit: Int?,
        minMaintenanceFee: Int?,
        maxMaintenanceFee: Int?
    ) -> String {
        var parts: [String] = []

        if let depositTitle = wonRangeTitle(min: minDeposit, max: maxDeposit) {
            parts.append("보증금 \(depositTitle)")
        }

        if let maintenanceFeeTitle = wonRangeTitle(min: minMaintenanceFee, max: maxMaintenanceFee) {
            parts.append("관리비 \(maintenanceFeeTitle)")
        }

        return parts.joined(separator: " · ")
    }

    nonisolated private static func locationTitle(from listing: Listing) -> String {
        if let nearestTransit = listing.nearestTransit {
            if let walkMinutes = nearestTransit.walkMinutes {
                return "\(nearestTransit.name) 도보 \(walkMinutes)분"
            }

            return nearestTransit.name
        }

        if let distanceMeters = listing.distanceMeters {
            return "\(Int(distanceMeters.rounded()))m 거리"
        }

        return listing.address ?? ""
    }

    nonisolated private static func stayPeriodTitle(min: Int?, max: Int?) -> String {
        switch (min, max) {
        case let (min?, max?) where min == max:
            return "\(min)개월"
        case let (min?, max?):
            return "\(min)~\(max)개월"
        case let (min?, nil):
            return "\(min)개월 이상"
        case let (nil, max?):
            return "최대 \(max)개월"
        case (nil, nil):
            return ""
        }
    }

    nonisolated private static func typeTitle(from type: String) -> String {
        switch type.uppercased() {
        case "GOSHIWON":
            return "Goshiwon"
        case "CO_LIVING":
            return "Co-living"
        case "SHARE_HOUSE":
            return "Share house"
        default:
            return type
                .replacingOccurrences(of: "_", with: " ")
                .lowercased()
                .capitalized
        }
    }

    nonisolated private static func wonRangeTitle(min: Int?, max: Int?) -> String? {
        switch (min, max) {
        case let (min?, max?) where min == max:
            return wonTitle(min)
        case let (min?, max?):
            return "\(wonNumberTitle(min))~\(wonTitle(max))"
        case let (min?, nil):
            return "\(wonTitle(min))~"
        case let (nil, max?):
            return "~\(wonTitle(max))"
        case (nil, nil):
            return nil
        }
    }

    nonisolated private static func wonTitle(_ amount: Int) -> String {
        guard amount != 0 else { return "0원" }
        guard amount >= 10_000 else { return "\(amount)원" }

        return "\(wonNumberTitle(amount))만원"
    }

    nonisolated private static func wonNumberTitle(_ amount: Int) -> String {
        guard amount >= 10_000 else { return "\(amount)원" }

        let tenths = amount / 1_000
        if tenths % 10 == 0 {
            return "\(tenths / 10)"
        }

        return "\(Double(tenths) / 10)"
    }
}
