import Foundation

enum ListingDetailValueFormatter {
    static func monthlyRentTitle(min: Int?, max: Int?, language: AppLanguage) -> String {
        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized("listingDetail.value.noPriceInfo")
        }

        return format("listingDetail.format.monthlyRent", language: language, range)
    }

    static func overviewDepositTitle(min: Int?, max: Int?, language: AppLanguage) -> String {
        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized("listingDetail.value.noDepositInfo")
        }

        return format("listingDetail.format.deposit.overview", language: language, range)
    }

    static func roomOfferPricingTitle(
        _ pricing: ListingDetailRoomPricing?,
        language: AppLanguage
    ) -> String {
        guard let pricing else {
            return language.localized("listingDetail.value.noPriceInfo")
        }

        let monthlyRent = pricing.monthlyRent.map {
            format(
                "listingDetail.format.monthlyRent",
                language: language,
                localizedWonAmount($0, language: language)
            )
        }
        let deposit = pricing.deposit.map {
            format(
                "listingDetail.format.deposit.roomOffer",
                language: language,
                localizedWonAmount($0, language: language)
            )
        }
        let values = [monthlyRent, deposit].compactMap { $0 }

        return values.isEmpty
            ? language.localized("listingDetail.value.noPriceInfo")
            : values.joined(separator: " · ")
    }

    static func priceRowValue(min: Int?, max: Int?, language: AppLanguage) -> String {
        localizedWonRange(min: min, max: max, language: language)
            ?? language.localized("listingDetail.value.noInfo")
    }

    static func overviewMaintenanceFeeTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        if min == 0, max == 0 {
            return language.localized("listingDetail.value.noMaintenanceFee")
        }

        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized("listingDetail.value.noMaintenanceFeeInfo")
        }

        return format("listingDetail.format.maintenanceFee.overview", language: language, range)
    }

    static func maintenanceFeeRowValue(min: Int?, max: Int?, language: AppLanguage) -> String {
        if min == 0, max == 0 {
            return language.localized("listingDetail.value.maintenanceFeeNotApplicable")
        }

        return priceRowValue(min: min, max: max, language: language)
    }

    static func stayTitle(_ contract: ListingDetailContract?, language: AppLanguage) -> String? {
        guard let contract else { return nil }

        switch (contract.minStayMonths, contract.maxStayMonths) {
        case let (min?, max?) where min == max:
            return format("listingDetail.format.stay.equal", language: language, String(min))
        case let (min?, max?):
            return format("listingDetail.format.stay.range", language: language, String(min), String(max))
        case let (min?, nil):
            return format("listingDetail.format.stay.minimum", language: language, String(min))
        case let (nil, max?):
            return format("listingDetail.format.stay.maximum", language: language, String(max))
        case (nil, nil):
            return nil
        }
    }

    static func floorTitle(_ building: ListingDetailBuilding, language: AppLanguage) -> String? {
        switch (building.usedFloorMin, building.usedFloorMax, building.totalFloors) {
        case let (min?, max?, total?) where min == max:
            return format("listingDetail.format.floor.equalOfTotal", language: language, String(min), String(total))
        case let (min?, max?, total?):
            return format("listingDetail.format.floor.rangeOfTotal", language: language, String(min), String(max), String(total))
        case let (min?, nil, total?):
            return format("listingDetail.format.floor.minimumOfTotal", language: language, String(min), String(total))
        case let (nil, max?, total?):
            return format("listingDetail.format.floor.maximumOfTotal", language: language, String(max), String(total))
        case let (nil, nil, total?):
            return format("listingDetail.format.floor.totalOnly", language: language, String(total))
        case let (min?, max?, nil) where min == max:
            return format("listingDetail.format.floor.equal", language: language, String(min))
        case let (min?, max?, nil):
            return format("listingDetail.format.floor.range", language: language, String(min), String(max))
        case let (min?, nil, nil):
            return format("listingDetail.format.floor.minimum", language: language, String(min))
        case let (nil, max?, nil):
            return format("listingDetail.format.floor.maximum", language: language, String(max))
        case (nil, nil, nil):
            return nil
        }
    }

    static func availabilityTitle(
        _ value: Bool?,
        availableKey: String,
        unavailableKey: String,
        language: AppLanguage
    ) -> String? {
        guard let value else { return nil }
        return language.localized(value ? availableKey : unavailableKey)
    }

    static func transitTitle(
        _ transit: ListingDetailNearestTransit?,
        includesFrom: Bool = false,
        language: AppLanguage
    ) -> String {
        guard let transit else { return language.localized("listingDetail.value.noTransitInfo") }
        let localizedName = if language == .korean {
            ListingDetailModel.localizedServerCode(
                transit.name,
                namespace: .nearestTransitName,
                language: language
            ) ?? transit.name
        } else {
            transit.name
        }
        guard let walkMinutes = transit.walkMinutes else { return localizedName }

        return format(
            includesFrom
                ? "listingDetail.format.transit.location"
                : "listingDetail.format.transit.overview",
            language: language,
            String(walkMinutes),
            localizedName
        )
    }

    static func commonSpaceTitle(type: String, count: Int?, language: AppLanguage) -> String {
        guard let count else { return type }
        return format("listingDetail.format.commonSpace.count", language: language, type, String(count))
    }

    private static func localizedWonRange(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String? {
        if language == .korean {
            return MonthlyRentPriceFormatter.wonRangeTitle(min: min, max: max)?
                .replacingOccurrences(of: "만원", with: "만 원")
        }

        return MonthlyRentPriceFormatter.amountRangeTitle(
            min: min,
            max: max,
            language: language
        )
    }

    private static func localizedWonAmount(_ amount: Int, language: AppLanguage) -> String {
        if language == .korean {
            return (MonthlyRentPriceFormatter.wonRangeTitle(min: amount, max: amount) ?? "")
                .replacingOccurrences(of: "만원", with: "만 원")
        }

        return compactWonAmount(amount)
    }

    private static func compactWonRange(min: Int?, max: Int?) -> String? {
        switch (min, max) {
        case let (min?, max?) where min == max:
            return compactWonAmount(min)
        case let (min?, max?):
            return "\(compactWonAmount(min))~\(compactWonNumber(max))"
        case let (min?, nil):
            return "\(compactWonAmount(min))~"
        case let (nil, max?):
            return "~\(compactWonAmount(max))"
        case (nil, nil):
            return nil
        }
    }

    private static func compactWonAmount(_ amount: Int) -> String {
        "₩\(compactWonNumber(amount))"
    }

    private static func compactWonNumber(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return "\(trimmedDecimal(Double(amount) / 1_000_000))M"
        }

        if amount >= 1_000 {
            return "\(trimmedDecimal(Double(amount) / 1_000))K"
        }

        return "\(amount)"
    }

    private static func trimmedDecimal(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private static func format(
        _ key: String,
        language: AppLanguage,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: language.localized(key),
            arguments: arguments
        )
    }
}
