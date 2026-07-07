//
//  ConvertMonthlyRentCurrencyUseCase.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture
import Foundation

struct ConvertMonthlyRentCurrencyUseCase: Sendable {
    var execute: @Sendable (_ monthlyRent: Int, _ exchangeRate: KRWToUSDExchangeRate) -> Decimal
}

extension ConvertMonthlyRentCurrencyUseCase: DependencyKey {
    static let liveValue = ConvertMonthlyRentCurrencyUseCase(
        execute: { monthlyRent, exchangeRate in
            Decimal(monthlyRent) * exchangeRate.usdPerKRW
        }
    )
}

extension DependencyValues {
    var convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase {
        get { self[ConvertMonthlyRentCurrencyUseCase.self] }
        set { self[ConvertMonthlyRentCurrencyUseCase.self] = newValue }
    }
}
