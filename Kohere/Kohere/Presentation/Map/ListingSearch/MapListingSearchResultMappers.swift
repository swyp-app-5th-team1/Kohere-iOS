//
//  MapListingSearchResultMappers.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

extension ListingItemModel {
    init(listing: Listing, language: AppLanguage) {
        self.init(
            id: listing.id,
            title: listing.title,
            thumbnailURL: listing.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: listing.minMonthlyRent,
                max: listing.maxMonthlyRent,
                language: language
            ),
            formattedUsdPrice: "",
            detailsDescription: Self.detailsTitle(
                minDeposit: listing.minDeposit,
                maxDeposit: listing.maxDeposit,
                minimumMaintenanceFee: listing.minMaintenanceFee,
                maximumMaintenanceFee: listing.maxMaintenanceFee,
                language: language
            ),
            locationDescription: Self.locationTitle(from: listing, language: language),
            typeTag: listing.type,
            period: Self.minimumStayPeriodTitle(months: listing.minStayMonths, language: language),
            isLiked: listing.isFavorited,
            favoriteCount: listing.favoriteCount
        )
    }

    init(
        listing: Listing,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase,
        language: AppLanguage
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
                max: listing.maxMonthlyRent,
                language: language
            ),
            formattedUsdPrice: convertedMonthlyRentText,
            detailsDescription: Self.detailsTitle(
                minDeposit: listing.minDeposit,
                maxDeposit: listing.maxDeposit,
                minimumMaintenanceFee: listing.minMaintenanceFee,
                maximumMaintenanceFee: listing.maxMaintenanceFee,
                language: language
            ),
            locationDescription: Self.locationTitle(from: listing, language: language),
            typeTag: listing.type,
            period: Self.minimumStayPeriodTitle(months: listing.minStayMonths, language: language),
            isLiked: listing.isFavorited,
            favoriteCount: listing.favoriteCount
        )
    }

    private static func detailsTitle(
        minDeposit: Int?,
        maxDeposit: Int?,
        minimumMaintenanceFee: Int?,
        maximumMaintenanceFee: Int?,
        language: AppLanguage
    ) -> String {
        var parts: [String] = []

        if let depositTitle = MonthlyRentPriceFormatter.amountRangeTitle(
            min: minDeposit,
            max: maxDeposit,
            language: language
        ) {
            parts.append(
                language.localized(.listingDetailFormatDepositOverview(depositTitle))
            )
        }

        if let maintenanceFeeTitle = MonthlyRentPriceFormatter.amountRangeTitle(
            min: minimumMaintenanceFee,
            max: maximumMaintenanceFee,
            language: language
        ) {
            parts.append(
                language.localized(.listingDetailFormatMaintenanceFeeOverview(maintenanceFeeTitle))
            )
        }

        return parts.joined(separator: " · ")
    }

    private static func locationTitle(
        from listing: Listing,
        language: AppLanguage
    ) -> String {
        if let nearestTransit = listing.nearestTransit {
            if let walkMinutes = nearestTransit.walkMinutes {
                return language.localized(
                    .listingDetailFormatTransitOverview(
                        "\(walkMinutes)",
                        nearestTransit.name
                    )
                )
            }

            return nearestTransit.name
        }

        if let distanceMeters = listing.distanceMeters {
            switch language {
            case .korean:
                return "\(Int(distanceMeters.rounded()))m 거리"
            case .english:
                return "\(Int(distanceMeters.rounded()))m away"
            }
        }

        return listing.address ?? ""
    }

    private static func minimumStayPeriodTitle(
        months: Int?,
        language: AppLanguage
    ) -> String {
        guard let months, months > 0 else { return "" }

        switch language {
        case .korean:
            return months == 1 ? "한달 이상" : "\(months)개월 이상"
        case .english:
            return "\(months) mo~"
        }
    }
}
