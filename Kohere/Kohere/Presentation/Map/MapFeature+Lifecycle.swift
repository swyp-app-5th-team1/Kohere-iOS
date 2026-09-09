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

        // 조회 중 화면을 떠났거나 실패했다면, 재진입 시 아직 받지 못한 전체 마커를 다시 조회한다.
        if state.listingSource == .diagnosis,
           state.diagnosisMapTotal == nil,
           state.diagnosisMapRequestID == nil,
           let diagnosisID = state.activeDiagnosisID {
            effects.append(startDiagnosisMapEffect(diagnosisID: diagnosisID, state: &state))
        }

        return .merge(effects)
    }

    func handleMapDismissed(state: inout State) -> Effect<Action> {
        state.isDiagnosisButtonExpanded = false
        state.isListingSearchLoading = false
        state.diagnosisMapRequestID = nil
        if state.selectedListingRequestID != nil {
            state.clearSelectedListing()
        }
        return .merge(
            .cancel(id: MapEffectID.exchangeRate),
            .cancel(id: MapEffectID.diagnosisButtonAutoCollapse),
            .cancel(id: MapEffectID.diagnosisDetail),
            .cancel(id: MapEffectID.diagnosisRecommendations),
            .cancel(id: MapEffectID.diagnosisMap),
            .cancel(id: MapEffectID.listingSearch),
            .cancel(id: MapEffectID.listingMapMarkers),
            .cancel(id: MapEffectID.selectedListing)
        )
    }
}
