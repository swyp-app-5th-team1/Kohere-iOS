//
//  MapFeature+ListingSearch.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

extension MapFeature {
    func canStartListingSearch(state: State) -> Bool {
        if state.lastSearchedViewport != nil {
            return true
        }

        return canStartFirstListingSearch(state: state)
    }

    func canStartFirstListingSearch(state: State) -> Bool {
        switch state.locationAuthorization {
        case .authorized:
            return state.hasMovedToInitialUserLocation
        case .denied, .restricted:
            return true
        case .notDetermined:
            return false
        }
    }

    func startListingSearchEffect(
        state: inout State,
        viewport: MapViewport
    ) -> Effect<Action> {
        state.lastSearchedViewport = viewport
        state.showsResearchButton = false
        state.selectedMarkerID = nil
        state.sheetMode = .listingList
        state.isListingSearchLoading = true
        state.listingSearchErrorMessage = nil

        let input = state.appliedFilter.listingSearchInput(bounds: viewport.visibleBounds)

        return .run { [listingClient] send in
            debugLogListingSearchRequest(input)

            do {
                let page = try await listingClient.fetchListings(input)
                await send(.listingSearchResponse(.success(page)))
            } catch {
                await send(.listingSearchResponse(.failure(error)))
            }
        }
        .cancellable(id: "MapFeature.listingSearch", cancelInFlight: true)
    }
}
