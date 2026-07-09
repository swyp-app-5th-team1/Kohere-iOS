//
//  MapDiagnosisMappers.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension ListingItemModel {
    nonisolated init(recommendation: DiagnosisRecommendedListing) {
        self.init(
            id: recommendation.listingID,
            title: recommendation.title,
            thumbnailURL: recommendation.thumbnailURL,
            formattedPrice: MonthlyRentPriceFormatter.wonTitle(
                min: recommendation.minMonthlyRent,
                max: recommendation.maxMonthlyRent
            ),
            formattedUsdPrice: "",
            detailsDescription: Self.depositTitle(
                min: recommendation.minDeposit,
                max: recommendation.maxDeposit
            ),
            locationDescription: recommendation.title.isEmpty ? "추천 매물" : recommendation.title,
            typeTag: Self.typeTitle(from: recommendation.type),
            period: "1 mo~",
            isLiked: false
        )
    }

    nonisolated init(
        recommendation: DiagnosisRecommendedListing,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase
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
                max: recommendation.maxMonthlyRent
            ),
            formattedUsdPrice: convertedMonthlyRentText,
            detailsDescription: Self.depositTitle(
                min: recommendation.minDeposit,
                max: recommendation.maxDeposit
            ),
            locationDescription: recommendation.title.isEmpty ? "추천 매물" : recommendation.title,
            typeTag: Self.typeTitle(from: recommendation.type),
            period: "1 mo~",
            isLiked: false
        )
    }

    nonisolated private static func depositTitle(min: Int?, max: Int?) -> String {
        MonthlyRentPriceFormatter.rangeTitle(prefix: "보증금", min: min, max: max)
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
