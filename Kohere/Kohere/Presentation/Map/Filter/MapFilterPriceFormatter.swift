//
//  MapFilterPriceFormatter.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import Foundation

enum MapFilterPriceFormatter {
    static func amountText(_ tenThousandWon: Int, locale: Locale) -> String {
        if locale.language.languageCode?.identifier == AppLanguage.korean.apiCode {
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
            return AppLanguage(locale: locale).localized(.mapFilterAny)
        case let .upperBound(maximum):
            return localizedPriceText(
                resource: .mapFilterPriceUnderFormat(amountText(maximum, locale: locale)),
                locale: locale
            )
        case let .lowerBound(minimum):
            return localizedPriceText(
                resource: .mapFilterPriceUpperOnlyFormat(amountText(minimum, locale: locale)),
                locale: locale
            )
        case let .range(minimum, maximum):
            return localizedPriceText(
                resource: .mapFilterPriceRangeFormat(
                    amountText(minimum, locale: locale),
                    amountText(maximum, locale: locale)
                ),
                locale: locale
            )
        }
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
            let price = localizedPriceText(
                resource: .mapFilterPriceUnderFormat(amountText(maximum, locale: locale)),
                locale: locale
            )
            return "\(prefix) \(price)"
        case let .lowerBound(minimum):
            let price = localizedPriceText(
                resource: .mapFilterPriceUpperOnlyFormat(amountText(minimum, locale: locale)),
                locale: locale
            )
            return "\(prefix) \(price)"
        case let .range(minimum, maximum):
            let price = localizedPriceText(
                resource: .mapFilterPriceRangeFormat(
                    amountText(minimum, locale: locale),
                    amountText(maximum, locale: locale)
                ),
                locale: locale
            )
            return "\(prefix) \(price)"
        }
    }

    private static func localizedPriceText(
        resource: LocalizedStringResource,
        locale: Locale
    ) -> String {
        AppLanguage(locale: locale).localized(resource)
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
