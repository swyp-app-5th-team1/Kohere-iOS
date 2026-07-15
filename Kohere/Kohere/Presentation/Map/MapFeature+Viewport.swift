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
        if let target = state.pendingViewportSearchTarget {
            state.showsResearchButton = false
            guard isCoordinate(target.coordinate, inside: viewport.visibleBounds) else {
                return .none
            }
            state.pendingViewportSearchTarget = nil
            return startListingSearchEffect(state: &state, viewport: viewport)
        }

        guard let lastSearchedViewport = state.lastSearchedViewport else {
            state.showsResearchButton = false
            return startListingSearchEffect(state: &state, viewport: viewport)
        }

        state.showsResearchButton = lastSearchedViewport != viewport
        return .none
    }

    private func handleDiagnosisViewportChanged(
        _ viewport: MapViewport,
        state: inout State
    ) -> Effect<Action> {
        guard let lastSearchedViewport = state.lastSearchedViewport else {
            state.lastSearchedViewport = viewport
            state.showsResearchButton = false
            return .none
        }

        state.showsResearchButton = lastSearchedViewport != viewport
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
