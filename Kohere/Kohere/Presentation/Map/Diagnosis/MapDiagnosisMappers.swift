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
        guard let rangeTitle = wonRangeTitle(min: min, max: max) else { return "" }
        return "보증금 \(rangeTitle)"
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
