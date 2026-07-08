//
//  MapFeature+ExchangeRate.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

extension MapFeature {
    func startExchangeRateFetchEffect() -> Effect<Action> {
        .run { [fetchKRWToUSDExchangeRateUseCase] send in
            do {
                let exchangeRate = try await fetchKRWToUSDExchangeRateUseCase.execute()
                await send(.exchangeRateResponse(.success(exchangeRate)))
            } catch {
                await send(.exchangeRateResponse(.failure(error)))
            }
        }
        .cancellable(id: "MapFeature.exchangeRate", cancelInFlight: true)
    }

    func applyExchangeRate(_ exchangeRate: KRWToUSDExchangeRate, to state: inout State) {
        state.krwToUSDExchangeRate = exchangeRate
        rebuildListingItems(to: &state)
    }
}
