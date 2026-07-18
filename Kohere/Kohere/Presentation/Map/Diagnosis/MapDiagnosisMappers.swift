//
//  MapDiagnosisMappers.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension ListingItemModel {
    nonisolated init(
        recommendation: DiagnosisRecommendedListing,
        language: AppLanguage
    ) {
        self.init(
            id: recommendation.listingID,
            title: recommendation.title,
            thumbnailURL: recommendation.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: recommendation.minMonthlyRent,
                max: recommendation.maxMonthlyRent,
                language: language
            ),
            formattedUsdPrice: "",
            detailsDescription: Self.depositTitle(
                min: recommendation.minDeposit,
                max: recommendation.maxDeposit,
                language: language
            ),
            locationDescription: recommendation.title.isEmpty
                ? Self.localized("map.diagnosis.matchesTitle", language: language)
                : recommendation.title,
            typeTag: recommendation.type,
            period: "1 mo~",
            isLiked: false
        )
    }

    nonisolated init(
        recommendation: DiagnosisRecommendedListing,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase,
        language: AppLanguage
    ) {
        let convertedMonthlyRentText: String
        if let exchangeRate {
            convertedMonthlyRentText = MonthlyRentPriceFormatter.usdTitle(
                min: recommendation.minMonthlyRent.map {
                    convertMonthlyRentCurrencyUseCase.execute($0, exchangeRate)
                },
                max: recommendation.maxMonthlyRent.map {
                    convertMonthlyRentCurrencyUseCase.execute($0, exchangeRate)
                }
            )
        } else {
            convertedMonthlyRentText = ""
        }

        self.init(
            id: recommendation.listingID,
            title: recommendation.title,
            thumbnailURL: recommendation.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: recommendation.minMonthlyRent,
                max: recommendation.maxMonthlyRent,
                language: language
            ),
            formattedUsdPrice: convertedMonthlyRentText,
            detailsDescription: Self.depositTitle(
                min: recommendation.minDeposit,
                max: recommendation.maxDeposit,
                language: language
            ),
            locationDescription: recommendation.title.isEmpty
                ? Self.localized("map.diagnosis.matchesTitle", language: language)
                : recommendation.title,
            typeTag: recommendation.type,
            period: "1 mo~",
            isLiked: false
        )
    }

    nonisolated private static func depositTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        guard let amount = MonthlyRentPriceFormatter.amountRangeTitle(
            min: min,
            max: max,
            language: language
        ) else { return "" }

        let format = localized("listingDetail.format.deposit.overview", language: language)
        return String(format: format, locale: language.locale, amount)
    }

    nonisolated private static func localized(_ key: String, language: AppLanguage) -> String {
        language.localized(key)
    }
}

extension MapFilterState {
    init(diagnosisDetail: DiagnosisDetail) {
        self.init()
        selectedOptions = Set(diagnosisDetail.conditions)

        monthlyRentRange = RangeSliderValue(
            minimum: diagnosisDetail.monthlyRentMin / 10_000,
            maximum: diagnosisDetail.monthlyRentMax / 10_000,
            bounds: MapFilterPriceRange.monthlyRent
        )
    }
}
