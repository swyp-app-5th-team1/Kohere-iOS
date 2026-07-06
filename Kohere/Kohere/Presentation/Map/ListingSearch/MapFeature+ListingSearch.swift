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

    private func appendUniqueListings(
        _ newListings: [Listing],
        to listings: inout [Listing]
    ) {
        var existingIDs = Set(listings.map(\.id))
        let uniqueListings = newListings.filter { existingIDs.insert($0.id).inserted }
        listings.append(contentsOf: uniqueListings)
    }
}
