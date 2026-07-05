//
//  MapDiagnosisMappers.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension ListingItemModel {
    init(recommendation: DiagnosisRecommendedListing) {
        self.init(
            id: recommendation.listingID,
            title: recommendation.title,
            formattedPrice: Self.monthlyRentTitle(from: recommendation.monthlyRent),
            formattedUsdPrice: "",
            detailsDescription: Self.depositTitle(from: recommendation.deposit),
            locationDescription: recommendation.title.isEmpty ? "추천 매물" : recommendation.title,
            typeTag: Self.typeTitle(from: recommendation.type),
            period: "1 mo~",
            isLiked: false
        )
    }

    private static func monthlyRentTitle(from monthlyRent: Int?) -> String {
        guard let monthlyRent else { return "가격 문의" }
        return "₩\(monthlyRent / 1000)K/mo"
    }

    private static func depositTitle(from deposit: Int?) -> String {
        guard let deposit else { return "Dep. 문의" }
        return "Dep. ₩\(deposit / 1000)K"
    }

    private static func typeTitle(from type: String) -> String {
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
