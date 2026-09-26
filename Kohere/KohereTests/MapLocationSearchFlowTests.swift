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
        var initialState = MapFeature.State()
        initialState.listingSource = .locationSearch
        initialState.listingSearchResults = [makeListing()]
        initialState.listingSearchErrorMessage = "이전 검색 오류"
        initialState.isListingSearchLoading = true

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.mapDismissed) {
            $0.isListingSearchLoading = false
        }

        XCTAssertEqual(store.state.listingSource, .locationSearch)
        XCTAssertEqual(store.state.listings.map(\.listingID), ["listing-1"])
        XCTAssertEqual(store.state.listingSearchErrorMessage, "이전 검색 오류")
    }

    // 진단 카드(목록)는 모드 전환과 함께 사라지고, 마커는 새 결과가 올 때까지 남는다.
    func testBrowseListingsLeavesDiagnosisModeKeepingMarkersUntilNewResults() async {
        let coordinate = MapCoordinate(latitude: 37.5559, longitude: 126.9250)
        let marker = MapMarkerItem(id: "listing-1", coordinate: coordinate)
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
        initialState.diagnosisRecommendedListings = [makeRecommendation()]
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
        XCTAssertTrue(store.state.listings.isEmpty)
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
        initialState.diagnosisRecommendedListings = [makeRecommendation()]
        initialState.isListingSearchLoading = true

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.placeSearchResultSelected(placeResult)) {
            $0.listingSource = .locationSearch
            $0.activeDiagnosisID = nil
            $0.appliedFilterSource = .manual
            $0.viewportSearchTrigger = .onArrival(at: coordinate)
            $0.selectedPlaceSearchTitle = placeResult.title
            $0.cameraMoveRequest = MapCameraMoveRequest(
                coordinate: coordinate,
                targetPosition: .center
            )
            $0.isListingSearchLoading = false
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
        initialState.viewportSearchTrigger = .onArrival(at: target)

        let store = TestStore(initialState: initialState) {
            MapFeature()
        } withDependencies: {
            $0.listingClient.fetchListings = { _ in
                ListingSearchPage(content: [], page: nil)
            }
            $0.listingClient.fetchMapMarkers = { _ in [] }
        }

        await store.send(.viewportChanged(outsideViewport)) {
            $0.currentViewport = outsideViewport
        }

        await store.send(.viewportChanged(targetViewport)) {
            $0.currentViewport = targetViewport
            $0.viewportSearchTrigger = .manual(lastSearched: targetViewport)
            $0.isListingSearchLoading = true
        }
        await store.receive {
            guard case .listingSearchResponse(.success, _) = $0 else { return false }
            return true
        } assert: {
            $0.isListingSearchLoading = false
        }
        await store.receive {
            guard case .listingMapMarkersResponse(.success) = $0 else { return false }
            return true
        }
    }

    func testPropertyTypeFilterAllowsOnlyOneSelection() {
        var filter = MapFilterState()

        filter.togglePropertyType(.goshiwon)
        filter.togglePropertyType(.coLiving)

        XCTAssertEqual(filter.selectedPropertyTypes, [.coLiving])
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
        initialState.viewportSearchTrigger = .manual(lastSearched: previousViewport)

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.viewportChanged(movedViewport)) {
            $0.currentViewport = movedViewport
            $0.showsResearchButton = true
        }
    }

    private func makeListing() -> Listing {
        Listing(
            listingID: "listing-1", title: "Listing", type: "Apartment",
            minMonthlyRent: 500_000, maxMonthlyRent: 500_000, minDeposit: 0, maxDeposit: 0,
            minMaintenanceFee: nil, maxMaintenanceFee: nil, minStayMonths: 6, maxStayMonths: nil,
            thumbnailURL: nil, coordinate: nil, address: "Seoul", nearestTransit: nil,
            distanceMeters: nil, isFavorited: false, favoriteCount: nil
        )
    }

    private func makeRecommendation() -> DiagnosisRecommendedListing {
        DiagnosisRecommendedListing(
            listingID: "listing-1", title: "Listing", type: "Apartment",
            minMonthlyRent: 500_000, maxMonthlyRent: 500_000, minDeposit: 0, maxDeposit: 0,
            thumbnailURL: nil, coordinate: nil, nearestTransit: nil
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
