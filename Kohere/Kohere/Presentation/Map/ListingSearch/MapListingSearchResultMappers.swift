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
            thumbnailURL: listing.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: listing.minMonthlyRent,
                max: listing.maxMonthlyRent
            ),
            formattedUsdPrice: "",
            detailsDescription: Self.detailsTitle(
                minDeposit: listing.minDeposit,
                maxDeposit: listing.maxDeposit,
                minimumMaintenanceFee: listing.minMaintenanceFee
            ),
            locationDescription: Self.locationTitle(from: listing),
            typeTag: listing.type,
            period: Self.minimumStayPeriodTitle(months: listing.minStayMonths),
            isLiked: listing.isFavorited,
            favoriteCount: listing.favoriteCount
        )
    }

    nonisolated init(
        listing: Listing,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase
    ) {
        let convertedMonthlyRentText: String
        if let exchangeRate {
            convertedMonthlyRentText = MonthlyRentPriceFormatter.usdTitle(
                min: listing.minMonthlyRent.map {
                    convertMonthlyRentCurrencyUseCase.execute($0, exchangeRate)
                },
                max: listing.maxMonthlyRent.map {
                    convertMonthlyRentCurrencyUseCase.execute($0, exchangeRate)
                }
            )
        } else {
            convertedMonthlyRentText = ""
        }

        self.init(
            id: listing.id,
            title: listing.title,
            thumbnailURL: listing.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: listing.minMonthlyRent,
                max: listing.maxMonthlyRent
            ),
            formattedUsdPrice: convertedMonthlyRentText,
            detailsDescription: Self.detailsTitle(
                minDeposit: listing.minDeposit,
                maxDeposit: listing.maxDeposit,
                minimumMaintenanceFee: listing.minMaintenanceFee
            ),
            locationDescription: Self.locationTitle(from: listing),
            typeTag: listing.type,
            period: Self.minimumStayPeriodTitle(months: listing.minStayMonths),
            isLiked: listing.isFavorited,
            favoriteCount: listing.favoriteCount
        )
    }

    nonisolated private static func detailsTitle(
        minDeposit: Int?,
        maxDeposit: Int?,
        minimumMaintenanceFee: Int?
    ) -> String {
        var parts: [String] = []

        if let depositTitle = wonRangeTitle(min: minDeposit, max: maxDeposit) {
            parts.append("보증금 \(depositTitle)")
        }

        if let maintenanceFeeTitle = wonRangeTitle(min: minimumMaintenanceFee, max: minimumMaintenanceFee) {
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

    nonisolated private static func minimumStayPeriodTitle(months: Int?) -> String {
        guard let months, months > 0 else { return "" }
        guard months != 1 else { return "한달 이상" }

        return "\(months)개월 이상"
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
