//
//  MonthlyRentPriceFormatter.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

enum MonthlyRentPriceFormatter {
    nonisolated static func rangeTitle(prefix: String, min: Int?, max: Int?) -> String {
        guard let rangeTitle = wonRangeTitle(min: min, max: max) else { return "" }
        return "\(prefix) \(rangeTitle)"
    }

    nonisolated static func wonTitle(min: Int?, max: Int?) -> String {
        guard let rangeTitle = wonRangeTitle(min: min, max: max) else {
            return "월세 정보 없음"
        }

        return "월세 \(rangeTitle)"
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

    nonisolated static func wonRangeTitle(min: Int?, max: Int?) -> String? {
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
