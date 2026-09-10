//
//  MapDiagnosisMappers.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension ListingItemModel {
    init(
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
            locationDescription: Self.transitTitle(recommendation.nearestTransit, language: language),
            typeTag: recommendation.type,
            period: "1 mo~",
            isLiked: false
        )
    }

    init(
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
            locationDescription: Self.transitTitle(recommendation.nearestTransit, language: language),
            typeTag: recommendation.type,
            period: "1 mo~",
            isLiked: false
        )
    }

    private static func depositTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        guard let amount = MonthlyRentPriceFormatter.amountRangeTitle(
            min: min,
            max: max,
            language: language
        ) else { return "" }

        return language.localized(.listingDetailFormatDepositOverview(amount))
    }
}

extension MapFilterState {
    init(diagnosisDetail: DiagnosisDetail) {
        // 진단에서 제공하지 않는 보증금에는 가격 제한을 추가하지 않는다.
        self.init()
        selectedOptions = Set(diagnosisDetail.conditions)

        monthlyRentRange = RangeSliderValue(
            minimum: diagnosisDetail.monthlyRentMin / 10_000,
            maximum: diagnosisDetail.monthlyRentMax / 10_000,
            bounds: MapFilterPriceRange.monthlyRent
        )
    }
}
