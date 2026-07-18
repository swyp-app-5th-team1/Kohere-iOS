//
//  MapFilterPriceFormatter.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import Foundation

enum MapFilterPriceFormatter {
    static func amountText(_ tenThousandWon: Int, locale: Locale) -> String {
        if locale.language.languageCode?.identifier == AppLanguage.korean.rawValue {
            return "\(tenThousandWon)만 원"
        }

        return compactWonText(tenThousandWon)
    }

    static func controlSummary(
        selection: RangeSliderValue,
        bounds: ClosedRange<Int>,
        locale: Locale
    ) -> String {
        switch rangeState(
            selection: selection,
            minimumBoundary: bounds.lowerBound,
            maximumBoundary: bounds.upperBound
        ) {
        case .all:
            return AppLanguage(locale: locale).localized("map.filter.any")
        case let .upperBound(maximum):
            return localizedPriceText(
                key: "map.filter.price.underFormat",
                amounts: [maximum],
                locale: locale
            )
        case let .lowerBound(minimum):
            return localizedPriceText(
                key: "map.filter.price.upperOnlyFormat",
                amounts: [minimum],
                locale: locale
            )
        case let .range(minimum, maximum):
            return localizedPriceText(
                key: "map.filter.price.rangeFormat",
                amounts: [minimum, maximum],
                locale: locale
            )
        }
    }

    static func chipTitle(
        prefix: String,
        selection: RangeSliderValue,
        defaultSelection: RangeSliderValue,
        locale: Locale
    ) -> String? {
        chipTitle(
            prefix: prefix,
            selection: selection,
            minimumBoundary: defaultSelection.minimum,
            maximumBoundary: defaultSelection.maximum,
            locale: locale
        )
    }

    static func chipTitle(
        prefix: String,
        selection: RangeSliderValue,
        bounds: ClosedRange<Int>,
        locale: Locale
    ) -> String? {
        chipTitle(
            prefix: prefix,
            selection: selection,
            minimumBoundary: bounds.lowerBound,
            maximumBoundary: bounds.upperBound,
            locale: locale
        )
    }

    private static func chipTitle(
        prefix: String,
        selection: RangeSliderValue,
        minimumBoundary: Int,
        maximumBoundary: Int,
        locale: Locale
    ) -> String? {
        switch rangeState(
            selection: selection,
            minimumBoundary: minimumBoundary,
            maximumBoundary: maximumBoundary
        ) {
        case .all:
            return nil
        case let .upperBound(maximum):
            return "\(prefix) \(localizedPriceText(key: "map.filter.price.underFormat", amounts: [maximum], locale: locale))"
        case let .lowerBound(minimum):
            return "\(prefix) \(localizedPriceText(key: "map.filter.price.upperOnlyFormat", amounts: [minimum], locale: locale))"
        case let .range(minimum, maximum):
            return "\(prefix) \(localizedPriceText(key: "map.filter.price.rangeFormat", amounts: [minimum, maximum], locale: locale))"
        }
    }

    private static func localizedPriceText(
        key: String,
        amounts: [Int],
        locale: Locale
    ) -> String {
        let format = AppLanguage(locale: locale).localized(key)
        let localizedAmounts = amounts.map { amountText($0, locale: locale) as CVarArg }
        return String(format: format, locale: locale, arguments: localizedAmounts)
    }

    private static func compactWonText(_ tenThousandWon: Int) -> String {
        guard tenThousandWon >= 100 else {
            return "₩\(tenThousandWon * 10)K"
        }

        let wholeMillions = tenThousandWon / 100
        let fractionalMillions = tenThousandWon % 100

        guard fractionalMillions > 0 else {
            return "₩\(wholeMillions)M"
        }

        let fraction = String(format: "%02d", fractionalMillions)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return "₩\(wholeMillions).\(fraction)M"
    }

    private static func rangeState(
        selection: RangeSliderValue,
        minimumBoundary: Int,
        maximumBoundary: Int
    ) -> RangeState {
        switch (selection.minimum, selection.maximum) {
        case (minimumBoundary, maximumBoundary):
            return .all
        case (minimumBoundary, let maximum):
            return .upperBound(maximum)
        case (let minimum, maximumBoundary):
            return .lowerBound(minimum)
        case let (minimum, maximum):
            return .range(minimum, maximum)
        }
    }
}

private enum RangeState {
    case all
    case upperBound(Int)
    case lowerBound(Int)
    case range(Int, Int)
}
