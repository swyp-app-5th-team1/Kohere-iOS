import Foundation

enum ListingDetailValueFormatter {
    static func monthlyRentTitle(min: Int?, max: Int?) -> String {
        guard let range = localizedWonRange(min: min, max: max) else {
            return String(localized: "listingDetail.value.noPriceInfo")
        }

        return format("listingDetail.format.monthlyRent", range)
    }

    static func overviewDepositTitle(min: Int?, max: Int?) -> String {
        guard let range = localizedWonRange(min: min, max: max) else {
            return String(localized: "listingDetail.value.noDepositInfo")
        }

        return format("listingDetail.format.deposit.overview", range)
    }

    static func roomOfferPricingTitle(_ pricing: ListingDetailRoomPricing?) -> String {
        guard let pricing else {
            return String(localized: "listingDetail.value.noPriceInfo")
        }

        let monthlyRent = pricing.monthlyRent.map {
            format("listingDetail.format.monthlyRent", localizedWonAmount($0))
        }
        let deposit = pricing.deposit.map {
            format("listingDetail.format.deposit.roomOffer", localizedWonAmount($0))
        }
        let values = [monthlyRent, deposit].compactMap { $0 }

        return values.isEmpty
            ? String(localized: "listingDetail.value.noPriceInfo")
            : values.joined(separator: " · ")
    }

    static func priceRowValue(min: Int?, max: Int?) -> String {
        localizedWonRange(min: min, max: max)
            ?? String(localized: "listingDetail.value.noInfo")
    }

    static func overviewMaintenanceFeeTitle(min: Int?, max: Int?) -> String {
        if min == 0, max == 0 {
            return String(localized: "listingDetail.value.noMaintenanceFee")
        }

        guard let range = localizedWonRange(min: min, max: max) else {
            return String(localized: "listingDetail.value.noMaintenanceFeeInfo")
        }

        return format("listingDetail.format.maintenanceFee.overview", range)
    }

    static func maintenanceFeeRowValue(min: Int?, max: Int?) -> String {
        if min == 0, max == 0 {
            return String(localized: "listingDetail.value.maintenanceFeeNotApplicable")
        }

        return priceRowValue(min: min, max: max)
    }

    static func stayTitle(_ contract: ListingDetailContract?) -> String? {
        guard let contract else { return nil }

        switch (contract.minStayMonths, contract.maxStayMonths) {
        case let (min?, max?) where min == max:
            return format("listingDetail.format.stay.equal", String(min))
        case let (min?, max?):
            return format("listingDetail.format.stay.range", String(min), String(max))
        case let (min?, nil):
            return format("listingDetail.format.stay.minimum", String(min))
        case let (nil, max?):
            return format("listingDetail.format.stay.maximum", String(max))
        case (nil, nil):
            return nil
        }
    }

    static func floorTitle(_ building: ListingDetailBuilding) -> String? {
        switch (building.usedFloorMin, building.usedFloorMax, building.totalFloors) {
        case let (min?, max?, total?) where min == max:
            return format("listingDetail.format.floor.equalOfTotal", String(min), String(total))
        case let (min?, max?, total?):
            return format("listingDetail.format.floor.rangeOfTotal", String(min), String(max), String(total))
        case let (min?, nil, total?):
            return format("listingDetail.format.floor.minimumOfTotal", String(min), String(total))
        case let (nil, max?, total?):
            return format("listingDetail.format.floor.maximumOfTotal", String(max), String(total))
        case let (nil, nil, total?):
            return format("listingDetail.format.floor.totalOnly", String(total))
        case let (min?, max?, nil) where min == max:
            return format("listingDetail.format.floor.equal", String(min))
        case let (min?, max?, nil):
            return format("listingDetail.format.floor.range", String(min), String(max))
        case let (min?, nil, nil):
            return format("listingDetail.format.floor.minimum", String(min))
        case let (nil, max?, nil):
            return format("listingDetail.format.floor.maximum", String(max))
        case (nil, nil, nil):
            return nil
        }
    }

    static func availabilityTitle(
        _ value: Bool?,
        availableKey: String,
        unavailableKey: String
    ) -> String? {
        guard let value else { return nil }
        return String(localized: String.LocalizationValue(value ? availableKey : unavailableKey))
    }

    static func transitTitle(_ transit: ListingDetailNearestTransit?, includesFrom: Bool = false) -> String {
        guard let transit else { return String(localized: "listingDetail.value.noTransitInfo") }
        let localizedName = if Bundle.main.preferredLocalizations.first == "ko" {
            ListingDetailModel.localizedServerCode(
                transit.name,
                namespace: .nearestTransitName
            ) ?? transit.name
        } else {
            transit.name
        }
        guard let walkMinutes = transit.walkMinutes else { return localizedName }

        return format(
            includesFrom
                ? "listingDetail.format.transit.location"
                : "listingDetail.format.transit.overview",
            String(walkMinutes),
            localizedName
        )
    }

    static func commonSpaceTitle(type: String, count: Int?) -> String {
        guard let count else { return type }
        return format("listingDetail.format.commonSpace.count", type, String(count))
    }

    private static var usesKoreanPriceFormat: Bool {
        Bundle.main.preferredLocalizations.first == "ko"
    }

    private static func localizedWonRange(min: Int?, max: Int?) -> String? {
        if usesKoreanPriceFormat {
            return MonthlyRentPriceFormatter.wonRangeTitle(min: min, max: max)?
                .replacingOccurrences(of: "만원", with: "만 원")
        }

        return compactWonRange(min: min, max: max)
    }

    private static func localizedWonAmount(_ amount: Int) -> String {
        if usesKoreanPriceFormat {
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

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: String(localized: String.LocalizationValue(key)),
            arguments: arguments
        )
    }
}
