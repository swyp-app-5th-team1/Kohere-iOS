//
//  KRWToUSDExchangeRate.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

struct KRWToUSDExchangeRate: Equatable, Sendable {
    let usdPerKRW: Decimal
}

enum CurrencyError: Error, Equatable, Sendable {
    case exchangeRateUnavailable
}

extension CurrencyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .exchangeRateUnavailable:
            "환율 정보를 가져올 수 없습니다."
        }
    }
}
