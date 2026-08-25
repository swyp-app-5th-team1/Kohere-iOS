//
//  MapFeature+Lifecycle.swift
//  Kohere
//
//  Created by Codex on 7/15/26.
//

import ComposableArchitecture

extension MapFeature {
    func handleMapAppeared(state: inout State) -> Effect<Action> {
        var effects: [Effect<Action>] = [
            startExchangeRateFetchEffect()
        ]

        if state.appliedFilterSource != .diagnosis,
           shouldExpandDiagnosisButtonToday(userDefaultsClient: userDefaultsClient) {
            state.isDiagnosisButtonExpanded = true
            effects.append(diagnosisButtonAutoCollapseEffect)
        }

        if state.listingSource == .idle {
            effects.append(.send(.initialLocationSearchRequested))
        }

        return .merge(effects)
    }

    func handleMapDismissed(state: inout State) -> Effect<Action> {
        state.isDiagnosisButtonExpanded = false
        state.isListingSearchLoading = false
        return .merge(
            .cancel(id: MapEffectID.exchangeRate),
            .cancel(id: MapEffectID.diagnosisButtonAutoCollapse),
            .cancel(id: MapEffectID.diagnosisDetail),
            .cancel(id: MapEffectID.diagnosisRecommendations),
            .cancel(id: MapEffectID.listingSearch),
            .cancel(id: MapEffectID.listingMapMarkers)
        )
    }
}
