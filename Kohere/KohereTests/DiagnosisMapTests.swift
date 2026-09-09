import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class DiagnosisMapTests: XCTestCase {
    func testMapAndRecommendationsStartTogetherAndLoadIndependently() async {
        let clock = TestClock()
        let requestID = UUID()
        let started = LockIsolated<Set<String>>([])
        let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.diagnosisClient.fetchRecommendationMap = { id in
                XCTAssertEqual(id, 42)
                started.withValue { _ = $0.insert("map") }
                try await clock.sleep(for: .seconds(1))
                return self.mapResult()
            }
            $0.diagnosisClient.fetchRecommendations = { input in
                XCTAssertEqual(input.diagnosisID, 42)
                XCTAssertEqual(input.page, 0)
                started.withValue { _ = $0.insert("list") }
                try await clock.sleep(for: .seconds(2))
                return self.recommendations()
            }
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
        }
        store.exhaustivity = .off
        await store.send(.diagnosisResultRequested(diagnosisID: 42, filter: MapFilterState()))
        await clock.advance(by: .seconds(1))
        await store.receive(\.diagnosisMapResponse)
        XCTAssertEqual(started.value, ["map", "list"])
        XCTAssertEqual(store.state.markers.map(\.id), ["first", "outside-page"])
        XCTAssertEqual(store.state.diagnosisMapTotal, 137)
        XCTAssertTrue(store.state.listings.isEmpty)
        XCTAssertTrue(store.state.isRecommendationsLoading)
        await clock.advance(by: .seconds(1))
        await store.receive(\.diagnosisRecommendationsResponse)
        XCTAssertEqual(store.state.listings.map(\.listingID), ["first"])
        XCTAssertEqual(store.state.markers.map(\.id), ["first", "outside-page"])
        XCTAssertFalse(store.state.isRecommendationsLoading)
        await store.finish()
    }

    func testLateFirstPageDoesNotDismissSelectedMarkerOrMoveCamera() async {
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 42
        state.selectedMarkerID = "outside-page"
        state.selectedListingRequestID = UUID()
        state.sheetMode = .selectedListing
        state.markers = mapResult().markers.map { .init(id: $0.listingID, coordinate: $0.coordinate) }
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
        }
        store.exhaustivity = .off
        await store.send(.diagnosisRecommendationsResponse(.success(recommendations()), isFirstPage: true))
        XCTAssertEqual(store.state.selectedMarkerID, "outside-page")
        XCTAssertEqual(store.state.selectedListingRequestID, state.selectedListingRequestID)
        XCTAssertEqual(store.state.sheetMode, .selectedListing)
        XCTAssertNil(store.state.cameraMoveRequest)
        XCTAssertEqual(store.state.markers, state.markers)
    }

    func testChangingFilterKeepsValuesAndIgnoresOldDiagnosisMap() async {
        let requestID = UUID()
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 42
        state.appliedFilterSource = .diagnosis
        state.diagnosisMapRequestID = requestID
        state.editingFilter.updateMonthlyRentMaximum(50)
        state.editingFilter.selectedOptions = [.privateBathroom]
        let store = TestStore(initialState: state) { MapFeature() }
        store.exhaustivity = .off
        await store.send(.filterApplyButtonTapped)
        XCTAssertEqual(store.state.listingSource, .locationSearch)
        XCTAssertEqual(store.state.appliedFilter, state.editingFilter)
        XCTAssertNil(store.state.activeDiagnosisID)
        XCTAssertNil(store.state.diagnosisMapRequestID)
        await store.send(.diagnosisMapResponse(requestID: requestID, .success(mapResult())))
        XCTAssertTrue(store.state.markers.isEmpty)
    }

    func testOlderMapRequestCannotReplaceNewDiagnosisMarkers() async {
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 43
        state.diagnosisMapRequestID = UUID()
        let store = TestStore(initialState: state) { MapFeature() }
        let oldRequestID = UUID()
        await store.send(.diagnosisMapResponse(requestID: oldRequestID, .success(mapResult())))
        await store.send(.diagnosisMapResponse(requestID: oldRequestID, .failure(.emptyResponse)))
        XCTAssertEqual(store.state.diagnosisMapRequestID, state.diagnosisMapRequestID)
    }

    func testMapFailureDoesNotClearRecommendationList() async {
        let requestID = UUID()
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.diagnosisMapRequestID = requestID
        state.diagnosisRecommendedListings = recommendations().listings
        let store = TestStore(initialState: state) { MapFeature() }
        store.exhaustivity = .off
        await store.send(.diagnosisMapResponse(requestID: requestID, .failure(.emptyResponse)))
        XCTAssertEqual(store.state.diagnosisRecommendedListings, state.diagnosisRecommendedListings)
        XCTAssertNil(store.state.diagnosisMapRequestID)
        XCTAssertNotNil(store.state.diagnosisMapErrorMessage)
    }

    func testMapDismissalCancelsPendingMapResponse() async {
        let clock = TestClock()
        let requestID = UUID()
        let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.diagnosisClient.fetchRecommendationMap = { _ in
                try await clock.sleep(for: .seconds(1))
                return self.mapResult()
            }
            $0.diagnosisClient.fetchRecommendations = { _ in
                try await clock.sleep(for: .seconds(1))
                return self.recommendations()
            }
        }
        store.exhaustivity = .off
        await store.send(.diagnosisResultRequested(diagnosisID: 42, filter: MapFilterState()))
        await store.send(.mapDismissed)
        XCTAssertNil(store.state.diagnosisMapRequestID)
        await clock.advance(by: .seconds(1))
        await store.send(.diagnosisMapResponse(requestID: requestID, .success(mapResult())))
        XCTAssertTrue(store.state.markers.isEmpty)
        await store.finish()
    }

    func testMapRouterUsesGuestOwnershipHeaderWithoutQuery() throws {
        let environment = APIEnvironment(baseURL: URL(string: "https://example.com")!)
        for guestID in [nil, "anonymous-test-session"] {
            let request = try DiagnosisRouter.recommendationMap(
                diagnosisID: 42, guestSessionID: guestID, environment
            ).asURLRequest()
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v2/diagnoses/42/recommendations/map")
            XCTAssertNil(request.url?.query)
            XCTAssertNil(request.httpBody)
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Guest-Session-Id"), guestID)
        }
    }

    func testMapReentryReloadsMissingMarkersWithoutReplacingLoadedRecommendations() async {
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 42
        state.appliedFilterSource = .diagnosis
        state.diagnosisRecommendedListings = recommendations().listings
        let requests = LockIsolated(0)
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.diagnosisClient.fetchRecommendationMap = { id in
                XCTAssertEqual(id, 42)
                requests.withValue { $0 += 1 }
                return self.mapResult()
            }
            $0.fetchKRWToUSDExchangeRateUseCase = .init { .init(usdPerKRW: 0.001) }
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
        }
        store.exhaustivity = .off
        await store.send(.mapAppeared)
        await store.receive(\.diagnosisMapResponse)
        await store.finish()
        XCTAssertEqual(store.state.diagnosisRecommendedListings, state.diagnosisRecommendedListings)
        XCTAssertEqual(store.state.diagnosisMapTotal, 137)
        XCTAssertEqual(requests.value, 1)
        await store.send(.mapAppeared)
        await store.finish()
        XCTAssertEqual(requests.value, 1)
    }

    func testMapResponsePreservesTotalAndSkipsUnplottableMarker() throws {
        let data = Data(#"{"markers":[{"listingId":"first","lat":37.55,"lng":126.92},{"listingId":"missing-coordinate"}],"total":600}"#.utf8)
        let result = try JSONDecoder().decode(DiagnosisRecommendationMapResponseDTO.self, from: data).toEntity()
        XCTAssertEqual(result.total, 600)
        XCTAssertEqual(result.markers, [ListingMapMarker(
            listingID: "first", coordinate: .init(latitude: 37.55, longitude: 126.92)
        )])
        let empty = try JSONDecoder().decode(
            DiagnosisRecommendationMapResponseDTO.self, from: Data(#"{"markers":[],"total":0}"#.utf8)
        ).toEntity()
        XCTAssertTrue(empty.markers.isEmpty)
        XCTAssertEqual(empty.total, 0)
    }

    private func mapResult() -> DiagnosisRecommendationMap {
        DiagnosisRecommendationMap(markers: ["first", "outside-page"].map {
            ListingMapMarker(listingID: $0, coordinate: .init(latitude: 37.55, longitude: 126.92))
        }, total: 137)
    }

    private func recommendations() -> DiagnosisRecommendations {
        DiagnosisRecommendations(listings: [DiagnosisRecommendedListing(
            listingID: "first", title: "First listing", type: "Goshiwon",
            minMonthlyRent: 300_000, maxMonthlyRent: 500_000,
            minDeposit: 0, maxDeposit: 100_000, thumbnailURL: nil,
            coordinate: .init(latitude: 37.55, longitude: 126.92), nearestTransit: nil
        )], page: .init(number: 0, size: 1, totalElements: 137, totalPages: 137, hasNext: true), suggestions: nil)
    }
}

@MainActor
final class DiagnosisRecommendationTransitTests: XCTestCase {
    func testMissingOrNullTransitKeepsOlderResponsesCompatibleAndHidesLocation() throws {
        for transit in [nil, NSNull()] as [Any?] {
            let recommendation = try decodeRecommendation(nearestTransit: transit)
            XCTAssertNil(recommendation.nearestTransit)
            XCTAssertEqual(recommendation.title, "영등포 워킹홀리데이 쉐어하우스")
            assertLocationTitles(recommendation, korean: "", english: "")
        }
    }

    func testTransitFlowsFromResponseToLocalizedCards() throws {
        let recommendation = try decodeRecommendation(nearestTransit: [
            "type": ["code": "SUBWAY", "label": "지하철"],
            "name": "영등포역",
            "walkMinutes": 6
        ])
        XCTAssertEqual(recommendation.nearestTransit, ListingNearestTransit(
            type: "SUBWAY", name: "영등포역", walkMinutes: 6
        ))
        assertLocationTitles(recommendation, korean: "영등포역 도보 6분", english: "6-min walk 영등포역")
    }

    func testTransitWithoutWalkMinutesDisplaysOnlyServerName() throws {
        let recommendation = try decodeRecommendation(nearestTransit: [
            "type": ["code": "SUBWAY", "label": "Subway"],
            "name": "Yeongdeungpo Sta."
        ])
        assertLocationTitles(recommendation, korean: "Yeongdeungpo Sta.", english: "Yeongdeungpo Sta.")
    }

    func testTransitWithoutNameDoesNotFallBackToListingTitle() throws {
        let recommendation = try decodeRecommendation(nearestTransit: [
            "type": ["code": "SUBWAY", "label": "Subway"],
            "walkMinutes": 6
        ])
        XCTAssertNil(recommendation.nearestTransit)
        assertLocationTitles(recommendation, korean: "", english: "")
    }

    private func decodeRecommendation(nearestTransit: Any?) throws -> DiagnosisRecommendedListing {
        var body: [String: Any] = [
            "listingId": "listing-1",
            "title": "영등포 워킹홀리데이 쉐어하우스"
        ]
        body["nearestTransit"] = nearestTransit
        let data = try JSONSerialization.data(withJSONObject: body)
        return try JSONDecoder().decode(DiagnosisRecommendedListingResponseDTO.self, from: data).toEntity()
    }

    private func assertLocationTitles(
        _ recommendation: DiagnosisRecommendedListing,
        korean: String,
        english: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for (language, expected) in [(AppLanguage.korean, korean), (.english, english)] {
            let item = ListingItemModel(recommendation: recommendation, language: language)
            let convertedItem = ListingItemModel(
                recommendation: recommendation,
                exchangeRate: .init(usdPerKRW: 0.001),
                convertMonthlyRentCurrencyUseCase: .liveValue,
                language: language
            )
            XCTAssertEqual(item.locationDescription, expected, file: file, line: line)
            XCTAssertEqual(convertedItem.locationDescription, expected, file: file, line: line)
        }
    }
}
