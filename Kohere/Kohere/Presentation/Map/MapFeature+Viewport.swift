//
//  MapFeature+Viewport.swift
//  Kohere
//
//  Created by Codex on 7/15/26.
//

import ComposableArchitecture

extension MapFeature {
    func handleViewportChanged(
        _ viewport: MapViewport,
        state: inout State
    ) -> Effect<Action> {
        state.currentViewport = viewport

        switch state.listingSource {
        case .idle:
            state.showsResearchButton = false
            return .none

        case .locationSearch:
            return handleLocationSearchViewportChanged(viewport, state: &state)

        case .diagnosis:
            return handleDiagnosisViewportChanged(viewport, state: &state)
        }
    }

    private func handleLocationSearchViewportChanged(
        _ viewport: MapViewport,
        state: inout State
    ) -> Effect<Action> {
        switch state.viewportSearchTrigger {
        case .onFirstIdle:
            state.showsResearchButton = false
            return startListingSearchEffect(state: &state, viewport: viewport)

        case let .onArrival(target):
            state.showsResearchButton = false
            guard isCoordinate(target, inside: viewport.visibleBounds) else {
                return .none
            }
            return startListingSearchEffect(state: &state, viewport: viewport)

        case let .manual(lastSearched):
            state.showsResearchButton = lastSearched != viewport
            return .none
        }
    }

    private func handleDiagnosisViewportChanged(
        _ viewport: MapViewport,
        state: inout State
    ) -> Effect<Action> {
        // 진단 추천은 영역과 무관하게 조회하므로, 첫 멈춤 영역은 재검색 버튼 기준으로만 쓴다.
        guard case let .manual(lastSearched) = state.viewportSearchTrigger else {
            state.viewportSearchTrigger = .manual(lastSearched: viewport)
            state.showsResearchButton = false
            return .none
        }

        state.showsResearchButton = lastSearched != viewport
        return .none
    }

    private func isCoordinate(
        _ coordinate: MapCoordinate,
        inside bounds: MapBounds
    ) -> Bool {
        coordinate.latitude >= bounds.southWest.latitude
            && coordinate.latitude <= bounds.northEast.latitude
            && coordinate.longitude >= bounds.southWest.longitude
            && coordinate.longitude <= bounds.northEast.longitude
    }
}
