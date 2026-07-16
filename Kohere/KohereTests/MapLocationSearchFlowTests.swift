//
//  MapLocationSearchFlowTests.swift
//  KohereTests
//
//  Created by Codex on 7/15/26.
//

import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class MapLocationSearchFlowTests: XCTestCase {
    func testMapDismissedStopsListingSearchLoadingWithoutClearingResults() async {
        let listing = makeListingItem()
        var initialState = MapFeature.State()
        initialState.listingSource = .locationSearch
        initialState.listings = [listing]
        initialState.listingSearchErrorMessage = "이전 검색 오류"
        initialState.isListingSearchLoading = true

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.mapDismissed) {
            $0.isListingSearchLoading = false
        }

        XCTAssertEqual(store.state.listingSource, .locationSearch)
        XCTAssertEqual(store.state.listings, [listing])
        XCTAssertEqual(store.state.listingSearchErrorMessage, "이전 검색 오류")
    }

    func testBrowseListingsLeavesDiagnosisModeWithoutClearingVisibleResults() async {
        let coordinate = MapCoordinate(latitude: 37.5559, longitude: 126.9250)
        let marker = MapMarkerItem(id: "listing-1", coordinate: coordinate)
        let listing = makeListingItem()
        var previousFilter = MapFilterState()
        previousFilter.selectedOptions = [.englishSupport]
        var initialState = MapFeature.State()
        initialState.listingSource = .diagnosis
        initialState.activeDiagnosisID = 1
        initialState.appliedFilter = previousFilter
        initialState.editingFilter = previousFilter
        initialState.appliedFilterSource = .diagnosis
        initialState.selectedMarkerID = marker.id
        initialState.sheetMode = .selectedListing
        initialState.markers = [marker]
        initialState.listings = [listing]
        initialState.isDiagnosisDetailLoading = true
        initialState.diagnosisErrorMessage = "이전 진단 오류"
        initialState.isRecommendationsLoading = true
        initialState.recommendationsErrorMessage = "이전 추천 오류"

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.browseListingsRequested) {
            $0.listingSource = .locationSearch
            $0.activeDiagnosisID = nil
            $0.appliedFilter = MapFilterState()
            $0.editingFilter = MapFilterState()
            $0.appliedFilterSource = .manual
            $0.selectedMarkerID = nil
            $0.sheetMode = .listingList
            $0.isDiagnosisDetailLoading = false
            $0.diagnosisErrorMessage = nil
            $0.isRecommendationsLoading = false
            $0.recommendationsErrorMessage = nil
        }

        XCTAssertEqual(store.state.markers, [marker])
        XCTAssertEqual(store.state.listings, [listing])
    }

    func testPlaceResultWaitsForTargetViewportAndClearsVisibleResults() async {
        let coordinate = MapCoordinate(latitude: 37.5559, longitude: 126.9250)
        let placeResult = SearchPlaceResult(
            id: "hongdae",
            title: "홍대입구역",
            roadAddress: "서울 마포구 양화로",
            address: "",
            coordinate: coordinate
        )
        var initialState = MapFeature.State()
        initialState.listingSource = .diagnosis
        initialState.activeDiagnosisID = 1
        initialState.appliedFilterSource = .diagnosis
        initialState.markers = [MapMarkerItem(id: "listing-1", coordinate: coordinate)]
        initialState.listings = [makeListingItem()]
        initialState.isListingSearchLoading = true

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.placeSearchResultSelected(placeResult)) {
            $0.listingSource = .locationSearch
            $0.activeDiagnosisID = nil
            $0.appliedFilterSource = .manual
            $0.pendingViewportSearchTarget = MapPendingViewportSearchTarget(coordinate: coordinate)
            $0.selectedPlaceSearchTitle = placeResult.title
            $0.cameraMoveRequest = MapCameraMoveRequest(
                coordinate: coordinate,
                targetPosition: .center
            )
            $0.isListingSearchLoading = false
            $0.listings = []
            $0.markers = []
        }
    }

    func testPendingTargetStartsSearchOnlyAfterViewportContainsCoordinate() async {
        let target = MapCoordinate(latitude: 37.5559, longitude: 126.9250)
        let outsideViewport = makeViewport(
            center: MapCoordinate(latitude: 37.5000, longitude: 127.0000),
            southWest: MapCoordinate(latitude: 37.4900, longitude: 126.9900),
            northEast: MapCoordinate(latitude: 37.5100, longitude: 127.0100)
        )
        let targetViewport = makeViewport(
            center: target,
            southWest: MapCoordinate(latitude: 37.5450, longitude: 126.9150),
            northEast: MapCoordinate(latitude: 37.5650, longitude: 126.9350)
        )
        var initialState = MapFeature.State()
        initialState.listingSource = .locationSearch
        initialState.pendingViewportSearchTarget = MapPendingViewportSearchTarget(coordinate: target)

        let store = TestStore(initialState: initialState) {
            MapFeature()
        } withDependencies: {
            $0.listingClient.fetchListings = { _ in
                ListingSearchPage(content: [], page: nil)
            }
        }

        await store.send(.viewportChanged(outsideViewport)) {
            $0.currentViewport = outsideViewport
        }

        await store.send(.viewportChanged(targetViewport)) {
            $0.currentViewport = targetViewport
            $0.pendingViewportSearchTarget = nil
            $0.lastSearchedViewport = targetViewport
            $0.isListingSearchLoading = true
        }
        await store.receive(\.listingSearchResponse.success) {
            $0.isListingSearchLoading = false
        }
    }

    func testViewportChangeAfterSearchOnlyShowsResearchButton() async {
        let previousViewport = makeViewport(
            center: MapCoordinate(latitude: 37.5559, longitude: 126.9250),
            southWest: MapCoordinate(latitude: 37.5450, longitude: 126.9150),
            northEast: MapCoordinate(latitude: 37.5650, longitude: 126.9350)
        )
        let movedViewport = makeViewport(
            center: MapCoordinate(latitude: 37.5659, longitude: 126.9350),
            southWest: MapCoordinate(latitude: 37.5550, longitude: 126.9250),
            northEast: MapCoordinate(latitude: 37.5750, longitude: 126.9450)
        )
        var initialState = MapFeature.State()
        initialState.listingSource = .locationSearch
        initialState.currentViewport = previousViewport
        initialState.lastSearchedViewport = previousViewport

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.viewportChanged(movedViewport)) {
            $0.currentViewport = movedViewport
            $0.showsResearchButton = true
        }
    }

    private func makeListingItem() -> ListingItemModel {
        ListingItemModel(
            id: "listing-1",
            formattedPrice: "₩500,000 / month",
            formattedUsdPrice: "$360 / month",
            detailsDescription: "Studio",
            locationDescription: "Seoul",
            typeTag: "Apartment",
            period: "6 months",
            isLiked: false
        )
    }

    private func makeViewport(
        center: MapCoordinate,
        southWest: MapCoordinate,
        northEast: MapCoordinate
    ) -> MapViewport {
        MapViewport(
            center: center,
            zoomLevel: 14,
            visibleBounds: MapBounds(southWest: southWest, northEast: northEast)
        )
    }
}
