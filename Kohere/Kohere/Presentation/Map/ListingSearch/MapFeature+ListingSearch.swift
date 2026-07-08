//
//  MapFeature+ListingSearch.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

extension MapFeature {
    func listingItemModels(
        from listings: [Listing],
        exchangeRate: KRWToUSDExchangeRate?
    ) -> [ListingItemModel] {
        listings.map {
            ListingItemModel(
                listing: $0,
                exchangeRate: exchangeRate,
                convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase
            )
        }
    }

    func listingItemModels(
        from recommendations: [DiagnosisRecommendedListing],
        exchangeRate: KRWToUSDExchangeRate?
    ) -> [ListingItemModel] {
        recommendations.map {
            ListingItemModel(
                recommendation: $0,
                exchangeRate: exchangeRate,
                convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase
            )
        }
    }

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
            if let placeSearchTarget = state.placeSearchTarget {
                state.showsResearchButton = false
                guard isViewport(viewport, centeredNear: placeSearchTarget.coordinate) else {
                    return .none
                }
                state.placeSearchTarget = nil
                return startListingSearchEffect(state: &state, viewport: viewport)
            }

            guard let lastSearchedViewport = state.lastSearchedViewport else {
                state.showsResearchButton = false
                guard canStartFirstListingSearch(state: state) else { return .none }
                return startListingSearchEffect(state: &state, viewport: viewport)
            }

            state.showsResearchButton = lastSearchedViewport != viewport
            return .none

        case .diagnosis:
            guard let lastSearchedViewport = state.lastSearchedViewport else {
                state.lastSearchedViewport = viewport
                state.showsResearchButton = false
                return .none
            }

            state.showsResearchButton = lastSearchedViewport != viewport
            return .none
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

        let input = state.appliedFilter.listingSearchInput(
            bounds: viewport.visibleBounds,
            source: state.appliedFilterSource
        )

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

    func startNextListingPageEffect(
        appearedListingID: String,
        state: inout State
    ) -> Effect<Action> {
        guard state.listings.last?.listingID == appearedListingID,
              !state.isListingSearchLoading,
              state.listingSource == .locationSearch,
              state.listingPageInfo?.hasNext == true,
              let lastSearchedViewport = state.lastSearchedViewport
        else { return .none }

        let nextPage = (state.listingPageInfo?.number ?? 0) + 1
        state.isListingSearchLoading = true
        state.listingSearchErrorMessage = nil

        let input = state.appliedFilter.listingSearchInput(
            bounds: lastSearchedViewport.visibleBounds,
            page: nextPage,
            source: state.appliedFilterSource
        )

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

    func startNextPageEffect(
        appearedListingID: String,
        state: inout State
    ) -> Effect<Action> {
        switch state.listingSource {
        case .locationSearch:
            return startNextListingPageEffect(appearedListingID: appearedListingID, state: &state)

        case .diagnosis:
            return startNextDiagnosisRecommendationPageEffect(appearedListingID: appearedListingID, state: &state)

        case .idle:
            return .none
        }
    }

    func clearDiagnosisRecommendationState(state: inout State) {
        state.isRecommendationsLoading = false
        state.recommendationsErrorMessage = nil
        state.diagnosisRecommendedListings = []
        state.diagnosisRecommendationSuggestions = nil
        state.diagnosisRecommendationPageInfo = nil
    }

    func cancelDiagnosisRequestEffects() -> Effect<Action> {
        .merge(
            .cancel(id: "MapFeature.diagnosisDetail"),
            .cancel(id: "MapFeature.diagnosisRecommendations")
        )
    }

    func startNextDiagnosisRecommendationPageEffect(
        appearedListingID: String,
        state: inout State
    ) -> Effect<Action> {
        guard state.listings.last?.listingID == appearedListingID,
              !state.isRecommendationsLoading,
              state.listingSource == .diagnosis,
              state.diagnosisRecommendationPageInfo?.hasNext == true,
              let diagnosisID = state.activeDiagnosisID
        else { return .none }

        let nextPage = (state.diagnosisRecommendationPageInfo?.number ?? 0) + 1
        let pageSize = state.diagnosisRecommendationPageInfo?.size ?? DiagnosisRecommendationsInput.defaultPageSize
        state.isRecommendationsLoading = true
        state.recommendationsErrorMessage = nil

        let input = DiagnosisRecommendationsInput(
            diagnosisID: diagnosisID,
            page: nextPage,
            size: pageSize
        )

        return .run { [diagnosisClient] send in
            do {
                let recommendations = try await diagnosisClient.fetchRecommendations(input)
                await send(.diagnosisRecommendationsResponse(.success(recommendations)))
            } catch {
                await send(.diagnosisRecommendationsResponse(.failure(error)))
            }
        }
        .cancellable(id: "MapFeature.diagnosisRecommendations", cancelInFlight: true)
    }

    func applyListingSearchPage(_ page: ListingSearchPage, to state: inout State) {
        state.listingPageInfo = page.page

        if (page.page?.number ?? 0) > 0, !state.listingSearchResults.isEmpty {
            appendUniqueListings(page.content, to: &state.listingSearchResults)
        } else {
            state.listingSearchResults = page.content
        }

        state.listings = listingItemModels(
            from: state.listingSearchResults,
            exchangeRate: state.krwToUSDExchangeRate
        )
        state.markers = state.listingSearchResults.compactMap { listing in
            guard let coordinate = listing.coordinate else { return nil }
            return MapMarkerItem(id: listing.id, coordinate: coordinate)
        }

        if let selectedMarkerID = state.selectedMarkerID,
           !state.markers.contains(where: { $0.id == selectedMarkerID }) {
            state.selectedMarkerID = nil
        }
    }

    func applyDiagnosisRecommendations(_ recommendations: DiagnosisRecommendations, to state: inout State) {
        let pageNumber = recommendations.page?.number ?? 0
        let shouldAppendPage = pageNumber > 0 && !state.diagnosisRecommendedListings.isEmpty
        state.diagnosisRecommendationPageInfo = recommendations.page

        if shouldAppendPage {
            appendUniqueRecommendations(recommendations.listings, to: &state.diagnosisRecommendedListings)
            appendUniqueMarkers(recommendations.markers, to: &state.markers)
        } else {
            state.selectedMarkerID = nil
            state.sheetMode = .listingList
            state.diagnosisRecommendedListings = recommendations.listings
            state.diagnosisRecommendationSuggestions = recommendations.suggestions
            state.markers = recommendations.markers

            let cameraCoordinate = recommendations.listings.compactMap(\.coordinate).first
                ?? recommendations.markers.first?.coordinate
            state.cameraMoveRequest = cameraCoordinate
            if cameraCoordinate == nil {
                state.lastSearchedViewport = state.currentViewport
            }
        }

        state.listings = listingItemModels(
            from: state.diagnosisRecommendedListings,
            exchangeRate: state.krwToUSDExchangeRate
        )
    }

    private func appendUniqueListings(
        _ newListings: [Listing],
        to listings: inout [Listing]
    ) {
        var existingIDs = Set(listings.map(\.id))
        let uniqueListings = newListings.filter { existingIDs.insert($0.id).inserted }
        listings.append(contentsOf: uniqueListings)
    }

    private func appendUniqueRecommendations(
        _ newRecommendations: [DiagnosisRecommendedListing],
        to recommendations: inout [DiagnosisRecommendedListing]
    ) {
        var existingIDs = Set(recommendations.map(\.listingID))
        let uniqueRecommendations = newRecommendations.filter { existingIDs.insert($0.listingID).inserted }
        recommendations.append(contentsOf: uniqueRecommendations)
    }

    private func appendUniqueMarkers(
        _ newMarkers: [MapMarkerItem],
        to markers: inout [MapMarkerItem]
    ) {
        var existingIDs = Set(markers.map(\.id))
        let uniqueMarkers = newMarkers.filter { existingIDs.insert($0.id).inserted }
        markers.append(contentsOf: uniqueMarkers)
    }

    private func isViewport(
        _ viewport: MapViewport,
        centeredNear coordinate: MapCoordinate
    ) -> Bool {
        let tolerance = 0.0001
        return abs(viewport.center.latitude - coordinate.latitude) < tolerance
            && abs(viewport.center.longitude - coordinate.longitude) < tolerance
    }
}
