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

    func rebuildListingItems(to state: inout State) {
        switch state.listingSource {
        case .locationSearch:
            state.listings = listingItemModels(
                from: state.listingSearchResults,
                exchangeRate: state.krwToUSDExchangeRate
            )

        case .diagnosis:
            state.listings = listingItemModels(
                from: state.diagnosisRecommendedListings,
                exchangeRate: state.krwToUSDExchangeRate
            )

        case .idle:
            return
        }

        applyFavoriteStatusOverrides(
            to: &state.listings,
            statusByID: state.favoriteStatusesByListingID
        )
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
                guard isCoordinate(placeSearchTarget.coordinate, inside: viewport.visibleBounds) else {
                    return .none
                }
                state.placeSearchTarget = nil
                return startListingSearchEffect(state: &state, viewport: viewport)
            }

            guard let lastSearchedViewport = state.lastSearchedViewport else {
                state.showsResearchButton = false
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

    func handleFilterApplyButtonTapped(state: inout State) -> Effect<Action> {
        let previousAppliedFilter = state.appliedFilter
        state.appliedFilter = state.editingFilter
        if state.appliedFilterSource != .diagnosis || state.appliedFilter != previousAppliedFilter {
            state.appliedFilterSource = .manual
        }
        state.isDiagnosisMatchesButtonExpanded = true
        state.isFilterPresented = false
        state.listingSource = .locationSearch
        state.activeDiagnosisID = nil
        state.placeSearchTarget = nil
        state.isDiagnosisDetailLoading = false
        state.diagnosisErrorMessage = nil
        clearDiagnosisRecommendationState(state: &state)
        let cancelDiagnosisRequests = cancelDiagnosisRequestEffects()
        guard let viewport = state.currentViewport else { return cancelDiagnosisRequests }
        return .merge(
            cancelDiagnosisRequests,
            startListingSearchEffect(state: &state, viewport: viewport)
        )
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

        rebuildListingItems(to: &state)
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
            state.cameraMoveRequest = cameraCoordinate.map {
                MapCameraMoveRequest(coordinate: $0, targetPosition: .center)
            }
            if cameraCoordinate == nil {
                state.lastSearchedViewport = state.currentViewport
            }
        }

        rebuildListingItems(to: &state)
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
