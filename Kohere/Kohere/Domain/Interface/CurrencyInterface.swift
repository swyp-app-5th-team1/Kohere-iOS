//
//  CurrencyInterface.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

protocol CurrencyInterface: Sendable {
    func fetchKRWToUSDExchangeRate() async throws -> KRWToUSDExchangeRate
}

struct CurrencyClient: Sendable {
    var fetchKRWToUSDExchangeRate: @Sendable () async throws -> KRWToUSDExchangeRate
}

extension CurrencyClient {
    init(repository: any CurrencyInterface) {
        self.init(
            fetchKRWToUSDExchangeRate: {
                try await repository.fetchKRWToUSDExchangeRate()
            }
        )
    }
}

extension DependencyValues {
    var currencyClient: CurrencyClient {
        get { self[CurrencyClient.self] }
        set { self[CurrencyClient.self] = newValue }
    }
}
