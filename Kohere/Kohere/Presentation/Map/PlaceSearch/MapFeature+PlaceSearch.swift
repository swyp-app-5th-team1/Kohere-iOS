//
//  MapFeature+PlaceSearch.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

extension MapFeature {
    func handlePlaceSearchResultSelected(
        _ placeResult: SearchPlaceResult,
        state: inout State
    ) -> Effect<Action> {
        state.placeSearchTarget = MapPlaceSearchTarget(
            coordinate: placeResult.coordinate
        )
        state.selectedPlaceSearchTitle = placeResult.title
        state.cameraMoveRequest = placeResult.coordinate
        state.listingSource = .locationSearch
        state.activeDiagnosisID = nil
        state.appliedFilterSource = .manual
        state.selectedMarkerID = nil
        state.sheetMode = .listingList
        state.isFilterPresented = false
        state.showsResearchButton = false
        state.lastSearchedViewport = nil
        state.listingPageInfo = nil
        state.listingSearchErrorMessage = nil
        state.isDiagnosisDetailLoading = false
        state.diagnosisErrorMessage = nil
        state.listingSearchResults = []
        clearDiagnosisRecommendationState(state: &state)
        state.listings = []
        state.markers = []

        return .merge(
            .cancel(id: "MapFeature.listingSearch"),
            cancelDiagnosisRequestEffects()
        )
    }
}
