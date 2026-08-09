//
//  MonthlyRentPriceFormatter.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

enum MonthlyRentPriceFormatter {
    nonisolated static func rangeTitle(
        prefix: String,
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        guard let rangeTitle = amountRangeTitle(min: min, max: max, language: language) else { return "" }
        return "\(prefix) \(rangeTitle)"
    }

    static func wonTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String {
        guard let rangeTitle = amountRangeTitle(min: min, max: max, language: language) else {
            return language.localized(.listingDetailValueNoPriceInfo)
        }

        return language.localized(.listingDetailFormatMonthlyRent(rangeTitle))
    }

    nonisolated static func usdTitle(
        min: Decimal?,
        max: Decimal?
    ) -> String {
        switch (min, max) {
        case let (minimum?, maximum?) where minimum == maximum:
            return "≈\(usdTitle(minimum))/mo"
        case let (minimum?, maximum?):
            return "≈$\(usdNumberTitle(minimum))~\(usdNumberTitle(maximum))/mo"
        case let (minimum?, nil):
            return "≈\(usdTitle(minimum))~/mo"
        case let (nil, maximum?):
            return "≈~\(usdTitle(maximum))/mo"
        case (nil, nil):
            return ""
        }
    }

    nonisolated static func usdTitle(from amount: Decimal) -> String {
        "≈\(usdTitle(amount))/mo"
    }

    nonisolated static func amountRangeTitle(
        min: Int?,
        max: Int?,
        language: AppLanguage
    ) -> String? {
        switch language {
        case .korean:
            koreanWonRangeTitle(min: min, max: max)
        case .english:
            compactWonRangeTitle(min: min, max: max)
        }
    }

    nonisolated static func wonRangeTitle(min: Int?, max: Int?) -> String? {
        koreanWonRangeTitle(min: min, max: max)
    }

    nonisolated private static func koreanWonRangeTitle(min: Int?, max: Int?) -> String? {
        switch (min, max) {
        case let (min?, max?) where min == max:
            return koreanWonTitle(min)
        case let (min?, max?):
            return "\(koreanWonNumberTitle(min))~\(koreanWonTitle(max))"
        case let (min?, nil):
            return "\(koreanWonTitle(min))~"
        case let (nil, max?):
            return "~\(koreanWonTitle(max))"
        case (nil, nil):
            return nil
        }
    }

    nonisolated private static func koreanWonTitle(_ amount: Int) -> String {
        guard amount != 0 else { return "0원" }
        guard amount >= 10_000 else { return "\(amount)원" }

        return "\(koreanWonNumberTitle(amount))만원"
    }

    nonisolated private static func koreanWonNumberTitle(_ amount: Int) -> String {
        guard amount >= 10_000 else { return "\(amount)원" }

        let tenths = amount / 1_000
        if tenths % 10 == 0 {
            return "\(tenths / 10)"
        }

        return "\(Double(tenths) / 10)"
    }

    nonisolated private static func compactWonRangeTitle(min: Int?, max: Int?) -> String? {
        switch (min, max) {
        case let (min?, max?) where min == max:
            return compactWonTitle(min)
        case let (min?, max?):
            let minimum = compactWonComponent(min)
            let maximum = compactWonComponent(max)

            if minimum.suffix == maximum.suffix {
                return "₩\(minimum.number)~\(maximum.number)\(maximum.suffix)"
            }

            let minimumText = "\(minimum.number)\(minimum.suffix)"
            let maximumText = "\(maximum.number)\(maximum.suffix)"
            return "₩\(minimumText)~\(maximumText)"
        case let (min?, nil):
            return "\(compactWonTitle(min))~"
        case let (nil, max?):
            return "~\(compactWonTitle(max))"
        case (nil, nil):
            return nil
        }
    }

    nonisolated private static func compactWonTitle(_ amount: Int) -> String {
        let component = compactWonComponent(amount)
        return "₩\(component.number)\(component.suffix)"
    }

    nonisolated private static func compactWonComponent(_ amount: Int) -> (number: String, suffix: String) {
        if amount >= 1_000_000 {
            return (decimalText(amount: amount, unit: 1_000_000), "M")
        }

        if amount >= 1_000 {
            return (decimalText(amount: amount, unit: 1_000), "K")
        }

        return ("\(amount)", "")
    }

    nonisolated private static func decimalText(amount: Int, unit: Int) -> String {
        let hundredths = amount * 100 / unit
        let whole = hundredths / 100
        let fraction = hundredths % 100

        guard fraction > 0 else { return "\(whole)" }
        if fraction.isMultiple(of: 10) {
            return "\(whole).\(fraction / 10)"
        }
        return String(format: "%d.%02d", whole, fraction)
    }

    nonisolated private static func usdTitle(_ amount: Decimal) -> String {
        "$\(usdNumberTitle(amount))"
    }

    nonisolated private static func usdNumberTitle(_ amount: Decimal) -> String {
        var amount = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &amount, 0, .plain)

        let number = NSDecimalNumber(decimal: rounded)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","

        return formatter.string(from: number) ?? "\(number.intValue)"
    }

}
