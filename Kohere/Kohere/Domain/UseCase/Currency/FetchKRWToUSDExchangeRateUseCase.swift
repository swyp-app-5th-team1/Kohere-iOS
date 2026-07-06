//
//  FetchKRWToUSDExchangeRateUseCase.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

struct FetchKRWToUSDExchangeRateUseCase {
    var execute: @Sendable () async throws -> KRWToUSDExchangeRate
}

extension FetchKRWToUSDExchangeRateUseCase: DependencyKey {
    static let liveValue: FetchKRWToUSDExchangeRateUseCase = {
        @Dependency(\.currencyClient)
        var currencyClient

        return FetchKRWToUSDExchangeRateUseCase {
            try await currencyClient.fetchKRWToUSDExchangeRate()
        }
    }()
}

extension DependencyValues {
    var fetchKRWToUSDExchangeRateUseCase: FetchKRWToUSDExchangeRateUseCase {
        get { self[FetchKRWToUSDExchangeRateUseCase.self] }
        set { self[FetchKRWToUSDExchangeRateUseCase.self] = newValue }
    }
}
