//
//  MapFeature+ListingSearch.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture
import Foundation

enum MapLocationSearchIntent {
    /// 지도 탭의 최초 진입이다. 현재 viewport가 없으면 첫 camera idle까지 검색을 기다린다.
    case initialEntry
    /// 기존 필터를 초기화하고 현재 지도 결과를 유지한 채 일반 매물을 둘러본다.
    case browseListings
    /// 장소 검색 결과로 이동한다. 이전 결과를 비우고 목표 좌표가 viewport에 들어오면 검색한다.
    case placeResult(SearchPlaceResult)
    /// 매물 상세에서 지도로 돌아온다. 이전 결과는 유지하고 목표 좌표 이동 뒤 검색한다.
    case listingPreview(MapCoordinate)
    /// 사용자가 옮긴 현재 viewport를 기준으로 명시적으로 다시 검색한다.
    case researchCurrentViewport
    /// 적용한 필터와 현재 viewport를 기준으로 다시 검색한다.
    case filterApplied
}

extension MapFeature {
    // MARK: - Entry

    func beginLocationSearch(
        _ intent: MapLocationSearchIntent,
        state: inout State
    ) -> Effect<Action> {
        switch intent {
        case .researchCurrentViewport:
            guard let viewport = state.currentViewport else { return .none }
            prepareLocationSearchMode(state: &state)
            state.pendingViewportSearchTarget = nil
            state.selectedPlaceSearchTitle = nil
            state.clearSelectedListing()
            return .merge(
                cancelDiagnosisRequestEffects(),
                startListingSearchEffect(state: &state, viewport: viewport)
            )

        case .filterApplied:
            prepareLocationSearchMode(state: &state)
            state.pendingViewportSearchTarget = nil
            let cancelDiagnosisRequests = cancelDiagnosisRequestEffects()
            guard let viewport = state.currentViewport else { return cancelDiagnosisRequests }
            return .merge(
                cancelDiagnosisRequests,
                startListingSearchEffect(state: &state, viewport: viewport)
            )

        case .initialEntry, .browseListings:
            prepareLocationSearchMode(state: &state)
            if case .browseListings = intent {
                state.appliedFilter = MapFilterState()
                state.editingFilter = MapFilterState()
            }
            state.appliedFilterSource = .manual
            state.pendingViewportSearchTarget = nil
            state.selectedPlaceSearchTitle = nil
            state.clearSelectedListing()
            let cancelDiagnosisRequests = cancelDiagnosisRequestEffects()
            guard let viewport = state.currentViewport else { return cancelDiagnosisRequests }
            return .merge(
                cancelDiagnosisRequests,
                startListingSearchEffect(state: &state, viewport: viewport)
            )

        case let .placeResult(placeResult):
            prepareLocationSearchMode(state: &state)
            state.appliedFilterSource = .manual
            state.pendingViewportSearchTarget = MapPendingViewportSearchTarget(
                coordinate: placeResult.coordinate
            )
            state.selectedPlaceSearchTitle = placeResult.title
            state.cameraMoveRequest = MapCameraMoveRequest(
                coordinate: placeResult.coordinate,
                targetPosition: .center
            )
            state.clearSelectedListing()
            state.isFilterPresented = false
            state.showsResearchButton = false
            state.lastSearchedViewport = nil
            state.listingPageInfo = nil
            state.isListingSearchLoading = false
            state.listingSearchErrorMessage = nil
            state.listingSearchResults = []
            state.listings = []
            state.markers = []
            return .merge(
                .cancel(id: MapEffectID.listingSearch),
                .cancel(id: MapEffectID.listingMapMarkers),
                cancelDiagnosisRequestEffects()
            )

        case let .listingPreview(coordinate):
            prepareLocationSearchMode(state: &state)
            state.path.removeAll()
            state.appliedFilterSource = .manual
            state.pendingViewportSearchTarget = MapPendingViewportSearchTarget(coordinate: coordinate)
            state.selectedPlaceSearchTitle = nil
            state.cameraMoveRequest = MapCameraMoveRequest(
                coordinate: coordinate,
                targetPosition: .upper
            )
            state.clearSelectedListing()
            state.isFilterPresented = false
            state.showsResearchButton = false
            state.lastSearchedViewport = nil
            state.listingPageInfo = nil
            state.isListingSearchLoading = false
            state.listingSearchErrorMessage = nil
            return .merge(
                .cancel(id: MapEffectID.listingSearch),
                .cancel(id: MapEffectID.listingMapMarkers),
                cancelDiagnosisRequestEffects()
            )
        }
    }

    private func prepareLocationSearchMode(state: inout State) {
        state.listingSource = .locationSearch
        state.activeDiagnosisID = nil
        state.isDiagnosisDetailLoading = false
        state.diagnosisErrorMessage = nil
        clearDiagnosisRecommendationState(state: &state)
    }

    // MARK: - Request / Response

    func startListingSearchEffect(
        state: inout State,
        viewport: MapViewport
    ) -> Effect<Action> {
        state.lastSearchedViewport = viewport
        state.showsResearchButton = false
        state.clearSelectedListing()
        state.isListingSearchLoading = true
        state.listingSearchErrorMessage = nil

        let input = state.appliedFilter.listingSearchInput(
            bounds: viewport.visibleBounds
        )

        let listingsEffect: Effect<Action> = .run { [listingClient] send in
            debugLogListingSearchRequest(input)

            do {
                let page = try await listingClient.fetchListings(input)
                await send(.listingSearchResponse(.success(page), isFirstPage: true))
            } catch {
                await send(.listingSearchResponse(.failure(error), isFirstPage: true))
            }
        }
        .cancellable(id: MapEffectID.listingSearch, cancelInFlight: true)

        let markersEffect: Effect<Action> = .run { [listingClient] send in
            do {
                let markers = try await listingClient.fetchMapMarkers(input)
                await send(.listingMapMarkersResponse(.success(markers)))
            } catch {
                await send(.listingMapMarkersResponse(.failure(error)))
            }
        }
        .cancellable(id: MapEffectID.listingMapMarkers, cancelInFlight: true)

        return .merge(listingsEffect, markersEffect)
    }

    func handleListingSearchResponse(
        _ result: Result<ListingSearchPage, Error>,
        isFirstPage: Bool,
        state: inout State
    ) -> Effect<Action> {
        guard state.listingSource == .locationSearch else { return .none }

        switch result {
        case let .success(page):
            debugLogListingSearchResponse(page)
            state.isListingSearchLoading = false
            state.listingSearchErrorMessage = nil
            applyListingSearchPage(page, isFirstPage: isFirstPage, to: &state)

        case let .failure(error):
            debugLogListingSearchError(error)
            state.isListingSearchLoading = false
            state.listingSearchErrorMessage = error.localizedDescription
        }

        return .none
    }

    func handleListingMapMarkersResponse(
        _ result: Result<[ListingMapMarker], Error>,
        state: inout State
    ) -> Effect<Action> {
        guard state.listingSource == .locationSearch else { return .none }

        switch result {
        case let .success(markers):
            state.markers = markers.map {
                MapMarkerItem(id: $0.listingID, coordinate: $0.coordinate)
            }
        case .failure:
            state.markers = []
        }

        return .none
    }

    // MARK: - Pagination

    func handleListingRowAppeared(
        _ listingID: String,
        state: inout State
    ) -> Effect<Action> {
        switch state.listingSource {
        case .locationSearch:
            return startNextListingPageEffect(appearedListingID: listingID, state: &state)

        case .diagnosis:
            return startNextDiagnosisRecommendationPageEffect(appearedListingID: listingID, state: &state)

        case .idle:
            return .none
        }
    }

    private func startNextListingPageEffect(
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
            page: nextPage
        )

        return .run { [listingClient] send in
            debugLogListingSearchRequest(input)

            do {
                let page = try await listingClient.fetchListings(input)
                await send(.listingSearchResponse(.success(page), isFirstPage: false))
            } catch {
                await send(.listingSearchResponse(.failure(error), isFirstPage: false))
            }
        }
        .cancellable(id: MapEffectID.listingSearch, cancelInFlight: true)
    }

    // MARK: - Result Mapping

    func applyListingSearchPage(
        _ page: ListingSearchPage,
        isFirstPage: Bool,
        to state: inout State
    ) {
        state.listingPageInfo = page.page

        if isFirstPage {
            state.listingSearchResults = page.content
        } else {
            state.listingSearchResults.appendUnique(contentsOf: page.content)
        }

        rebuildListingItems(to: &state)

        if let selectedMarkerID = state.selectedMarkerID,
           !state.markers.contains(where: { $0.id == selectedMarkerID }) {
            state.clearSelectedListing()
        }
    }

    // MARK: - Shared Listing Presentation

    func listingItemModels(
        from listings: [Listing],
        exchangeRate: KRWToUSDExchangeRate?,
        language: AppLanguage
    ) -> [ListingItemModel] {
        listings.map {
            ListingItemModel(
                listing: $0,
                exchangeRate: exchangeRate,
                convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
                language: language
            )
        }
    }

    func listingItemModels(
        from recommendations: [DiagnosisRecommendedListing],
        exchangeRate: KRWToUSDExchangeRate?,
        language: AppLanguage
    ) -> [ListingItemModel] {
        recommendations.map {
            ListingItemModel(
                recommendation: $0,
                exchangeRate: exchangeRate,
                convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
                language: language
            )
        }
    }

    func rebuildListingItems(to state: inout State) {
        switch state.listingSource {
        case .locationSearch:
            state.listings = listingItemModels(
                from: state.listingSearchResults,
                exchangeRate: state.krwToUSDExchangeRate,
                language: state.appLanguage
            )

        case .diagnosis:
            state.listings = listingItemModels(
                from: state.diagnosisRecommendedListings,
                exchangeRate: state.krwToUSDExchangeRate,
                language: state.appLanguage
            )

        case .idle:
            return
        }

        applyFavoriteStatusOverrides(
            to: &state.listings,
            statusByID: state.favoriteStatusesByListingID
        )
    }
}
