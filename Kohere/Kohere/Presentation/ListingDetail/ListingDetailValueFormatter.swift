import Foundation

enum ListingDetailValueFormatter {
    static func monthlyRentTitle(min: Int?, max: Int?, language: AppLanguage) -> String {
        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized(.listingDetailValueNoPriceInfo)
        }

        return language.localized(.listingDetailFormatMonthlyRent(range))
    }

    static func overviewDepositTitle(min: Int?, max: Int?, language: AppLanguage) -> String {
        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized(.listingDetailValueNoDepositInfo)
        }

        return language.localized(.listingDetailFormatDepositOverview(range))
    }

    static func roomOfferPricingTitle(
        _ pricing: ListingDetailRoomPricing?,
        language: AppLanguage
    ) -> String {
        guard let pricing else {
            return language.localized(.listingDetailValueNoPriceInfo)
        }

        let monthlyRent = pricing.monthlyRent.map {
            language.localized(
                .listingDetailFormatMonthlyRent(localizedWonAmount($0, language: language))
            )
        }
        let deposit = pricing.deposit.map {
            language.localized(
                .listingDetailFormatDepositRoomOffer(localizedWonAmount($0, language: language))
            )
        }
        let values = [monthlyRent, deposit].compactMap { $0 }

        return values.isEmpty
            ? language.localized(.listingDetailValueNoPriceInfo)
            : values.joined(separator: " · ")
    }

    static func priceRowValue(min: Int?, max: Int?, language: AppLanguage) -> String {
        localizedWonRange(min: min, max: max, language: language)
            ?? language.localized(.listingDetailValueNoInfo)
    }

    static func overviewMaintenanceFeeTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        if min == 0, max == 0 {
            return language.localized(.listingDetailValueNoMaintenanceFee)
        }

        guard let range = localizedWonRange(min: min, max: max, language: language) else {
            return language.localized(.listingDetailValueNoMaintenanceFeeInfo)
        }

        return language.localized(.listingDetailFormatMaintenanceFeeOverview(range))
    }

    static func maintenanceFeeRowValue(min: Int?, max: Int?, language: AppLanguage) -> String {
        if min == 0, max == 0 {
            return language.localized(.listingDetailValueMaintenanceFeeNotApplicable)
        }

        return priceRowValue(min: min, max: max, language: language)
    }

    static func stayTitle(_ contract: ListingDetailContract?, language: AppLanguage) -> String? {
        guard let contract else { return nil }

        switch (contract.minStayMonths, contract.maxStayMonths) {
        case let (min?, max?) where min == max:
            return language.localized(.listingDetailFormatStayEqual(String(min)))
        case let (min?, max?):
            return language.localized(.listingDetailFormatStayRange(String(min), String(max)))
        case let (min?, nil):
            return language.localized(.listingDetailFormatStayMinimum(String(min)))
        case let (nil, max?):
            return language.localized(.listingDetailFormatStayMaximum(String(max)))
        case (nil, nil):
            return nil
        }
    }

    static func floorTitle(_ building: ListingDetailBuilding, language: AppLanguage) -> String? {
        switch (building.usedFloorMin, building.usedFloorMax, building.totalFloors) {
        case let (min?, max?, total?) where min == max:
            return language.localized(.listingDetailFormatFloorEqualOfTotal(String(min), String(total)))
        case let (min?, max?, total?):
            return language.localized(
                .listingDetailFormatFloorRangeOfTotal(String(min), String(max), String(total))
            )
        case let (min?, nil, total?):
            return language.localized(.listingDetailFormatFloorMinimumOfTotal(String(min), String(total)))
        case let (nil, max?, total?):
            return language.localized(.listingDetailFormatFloorMaximumOfTotal(String(max), String(total)))
        case let (nil, nil, total?):
            return language.localized(.listingDetailFormatFloorTotalOnly(String(total)))
        case let (min?, max?, nil) where min == max:
            return language.localized(.listingDetailFormatFloorEqual(String(min)))
        case let (min?, max?, nil):
            return language.localized(.listingDetailFormatFloorRange(String(min), String(max)))
        case let (min?, nil, nil):
            return language.localized(.listingDetailFormatFloorMinimum(String(min)))
        case let (nil, max?, nil):
            return language.localized(.listingDetailFormatFloorMaximum(String(max)))
        case (nil, nil, nil):
            return nil
        }
    }

    static func availabilityTitle(
        _ value: Bool?,
        availableResource: LocalizedStringResource,
        unavailableResource: LocalizedStringResource,
        language: AppLanguage
    ) -> String? {
        guard let value else { return nil }
        return language.localized(value ? availableResource : unavailableResource)
    }

    static func transitTitle(
        _ transit: ListingDetailNearestTransit?,
        includesFrom: Bool = false,
        language: AppLanguage
    ) -> String {
        guard let transit else { return language.localized(.listingDetailValueNoTransitInfo) }
        guard let walkMinutes = transit.walkMinutes else { return transit.name }

        return includesFrom
            ? language.localized(.listingDetailFormatTransitLocation(String(walkMinutes), transit.name))
            : language.localized(.listingDetailFormatTransitOverview(String(walkMinutes), transit.name))
    }

    static func commonSpaceTitle(type: String, count: Int?, language: AppLanguage) -> String {
        guard let count else { return type }
        return language.localized(.listingDetailFormatCommonSpaceCount(type, String(count)))
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

}
