import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class MapPriceFilterTests: XCTestCase {
    func testInitialSearchOmitsPricesAndOpeningThenDismissingKeepsThemUnapplied() async {
        let listRequests = LockIsolated<[ListingSearchInput]>([])
        let markerRequests = LockIsolated<[ListingSearchInput]>([])
        let clock = TestClock()
        var state = MapFeature.State()
        state.currentViewport = viewport
        let store = makeSearchStore(state, listRequests, markerRequests, clock)

        await store.send(.initialLocationSearchRequested) {
            $0.listingSource = .locationSearch
            $0.lastSearchedViewport = self.viewport
            $0.isListingSearchLoading = true
        }
        await receiveSearch(store, clock)
        XCTAssertEqual(listRequests.value.count, 1)
        XCTAssertEqual(markerRequests.value, listRequests.value)
        for input in listRequests.value {
            assertPriceQueries(input, equal: [:])
        }
        XCTAssertEqual(store.state.appliedFilter, MapFilterState())

        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        XCTAssertEqual(store.state.editingFilter.monthlyRentRange.maximum, 100)
        XCTAssertEqual(store.state.editingFilter.depositRange.maximum, 300)
        await store.send(.monthlyRentMaximumChanged(40)) {
            $0.editingFilter.updateMonthlyRentMaximum(40)
        }
        await store.send(.filterDismissed) {
            $0.editingFilter = MapFilterState()
            $0.isFilterPresented = false
        }
        XCTAssertEqual(store.state.appliedFilter, MapFilterState())
        XCTAssertEqual(listRequests.value.count, 1)
        await store.finish()
    }

    func testApplyingSelectedCapsSendsThemToListAndMarkers() async {
        let listRequests = LockIsolated<[ListingSearchInput]>([])
        let markerRequests = LockIsolated<[ListingSearchInput]>([])
        let clock = TestClock()
        var state = MapFeature.State()
        state.currentViewport = viewport
        let store = makeSearchStore(state, listRequests, markerRequests, clock)

        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        await store.send(.monthlyRentMaximumChanged(50)) {
            $0.editingFilter.updateMonthlyRentMaximum(50)
        }
        await store.send(.depositMaximumChanged(150)) {
            $0.editingFilter.updateDepositMaximum(150)
        }
        await store.send(.filterApplyButtonTapped) {
            $0.appliedFilter = self.boundedFilter
            $0.isFilterPresented = false
            $0.listingSource = .locationSearch
            $0.lastSearchedViewport = self.viewport
            $0.isListingSearchLoading = true
        }
        await receiveSearch(store, clock)
        XCTAssertEqual(listRequests.value.count, 1)
        XCTAssertEqual(markerRequests.value, listRequests.value)
        for input in listRequests.value {
            assertPriceQueries(input, equal: ["maxBudget": "500000", "maxDeposit": "1500000"])
        }

        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        await store.send(.depositMaximumChanged(200)) {
            $0.editingFilter.updateDepositMaximum(200)
        }
        await store.send(.filterDismissed) {
            $0.editingFilter = self.boundedFilter
            $0.isFilterPresented = false
        }
        XCTAssertEqual(store.state.appliedFilter, boundedFilter)
        XCTAssertEqual(listRequests.value.count, 1)
        await store.finish()
    }

    func testApplyingDefaultsOmitsPricesAndReopensAsUnrestricted() async {
        let listRequests = LockIsolated<[ListingSearchInput]>([])
        let markerRequests = LockIsolated<[ListingSearchInput]>([])
        let clock = TestClock()
        var state = MapFeature.State()
        state.currentViewport = viewport
        let store = makeSearchStore(state, listRequests, markerRequests, clock)

        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        await store.send(.filterApplyButtonTapped) {
            $0.isFilterPresented = false
            $0.listingSource = .locationSearch
            $0.lastSearchedViewport = self.viewport
            $0.isListingSearchLoading = true
        }
        await receiveSearch(store, clock)
        XCTAssertEqual(listRequests.value.count, 1)
        XCTAssertEqual(markerRequests.value, listRequests.value)
        for input in listRequests.value {
            assertPriceQueries(input, equal: [:])
        }
        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        XCTAssertEqual(store.state.editingFilter, MapFilterState())
        XCTAssertFalse(store.state.editingFilter.hasSelectedPriceRange)
        await store.finish()
    }

    func testResetOnlyChangesDraftUntilApplyClearsFiltersFromBothRequests() async {
        let listRequests = LockIsolated<[ListingSearchInput]>([])
        let markerRequests = LockIsolated<[ListingSearchInput]>([])
        let clock = TestClock()
        var previousFilter = boundedFilter
        previousFilter.selectedOptions = [.englishSupport]
        previousFilter.selectedPropertyTypes = [.goshiwon]
        var state = MapFeature.State()
        state.currentViewport = viewport
        state.listingSource = .locationSearch
        state.appliedFilter = previousFilter
        state.editingFilter = previousFilter
        state.isFilterPresented = true
        let store = makeSearchStore(state, listRequests, markerRequests, clock)

        await store.send(.filterResetButtonTapped) { $0.editingFilter = MapFilterState() }
        XCTAssertEqual(store.state.appliedFilter, previousFilter)
        await store.send(.filterDismissed) {
            $0.editingFilter = previousFilter
            $0.isFilterPresented = false
        }
        XCTAssertTrue(listRequests.value.isEmpty)
        XCTAssertTrue(markerRequests.value.isEmpty)
        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        await store.send(.filterResetButtonTapped) { $0.editingFilter = MapFilterState() }
        await store.send(.filterApplyButtonTapped) {
            $0.appliedFilter = MapFilterState()
            $0.isFilterPresented = false
            $0.lastSearchedViewport = self.viewport
            $0.isListingSearchLoading = true
        }
        await receiveSearch(store, clock)
        XCTAssertEqual(listRequests.value.count, 1)
        XCTAssertEqual(markerRequests.value, listRequests.value)
        for input in listRequests.value {
            assertPriceQueries(input, equal: [:])
            XCTAssertTrue(input.conditions.isEmpty)
            XCTAssertTrue(input.propertyTypes.isEmpty)
        }
        XCTAssertFalse(store.state.appliedFilter.hasSelectedPriceRange)
        await store.finish()
    }

    func testRightEndpointsOmitOnlyUpperLimits() {
        var filter = MapFilterState()
        filter.updateMonthlyRentMinimum(50)
        filter.updateDepositMinimum(150)
        assertPriceQueries(
            filter.listingSearchInput(bounds: viewport.visibleBounds),
            equal: ["minBudget": "500000", "minDeposit": "1500000"]
        )
    }

    func testBoundedRangesSendBothLimits() {
        var filter = boundedFilter
        filter.updateMonthlyRentMinimum(30)
        filter.updateDepositMinimum(75)
        assertPriceQueries(
            filter.listingSearchInput(bounds: viewport.visibleBounds),
            equal: [
                "minBudget": "300000", "maxBudget": "500000",
                "minDeposit": "750000", "maxDeposit": "1500000"
            ]
        )
    }

    func testPriceChipsMatchActualLimitsInBothLanguages() throws {
        for language in [AppLanguage.korean, .english] {
            let filter = MapFilterState()
            for (selection, bounds) in [
                (filter.monthlyRentRange, MapFilterPriceRange.monthlyRent),
                (filter.depositRange, MapFilterPriceRange.deposit)
            ] {
                XCTAssertEqual(
                    MapFilterPriceFormatter.controlSummary(
                        selection: selection, bounds: bounds, locale: language.locale
                    ),
                    language.localized(.mapFilterAny)
                )
            }
            let defaultChip = try priceChip(MapFilterState(), language)
            XCTAssertEqual(defaultChip.title, language.localized(.mapFilterSectionPrice))
            XCTAssertTrue(defaultChip.showsChevron)

            let chip = try priceChip(boundedFilter, language)
            XCTAssertFalse(chip.showsChevron)
            XCTAssertTrue(chip.title.contains(language.localized(.mapFilterMonthlyRent)))
            XCTAssertTrue(chip.title.contains(language.localized(.mapFilterDeposit)))
            let expectedAmounts = language == .korean ? ["50만 원", "150만 원"] : ["₩500K", "₩1.5M"]
            for amount in expectedAmounts {
                XCTAssertTrue(chip.title.contains(amount), chip.title)
            }
        }
    }

    func testDiagnosisMonthlyCapSurvivesManualOptionEditWithoutAddingDepositCap() async {
        let detail = DiagnosisDetail(
            diagnosisID: 1, region: "SEOUL", purpose: "STUDY", university: nil, district: nil,
            conditions: [.englishSupport], monthlyRentMin: 0, monthlyRentMax: 500_000,
            arcStatus: "HAS_ARC", status: "COMPLETED", submittedAt: "2026-09-09"
        )
        let filter = MapFilterState(diagnosisDetail: detail)
        assertPriceQueries(filter.listingSearchInput(bounds: viewport.visibleBounds), equal: ["maxBudget": "500000"])
        XCTAssertEqual(ChatBotFeature.State().diagnosisFilter.depositRange.maximum, 300)

        var state = MapFeature.State()
        state.appliedFilter = filter
        state.editingFilter = filter
        state.appliedFilterSource = .diagnosis
        state.listingSource = .diagnosis
        let store = TestStore(initialState: state) { MapFeature() }
        await store.send(.filterButtonTapped) { $0.isFilterPresented = true }
        await store.send(.filterOptionTapped(.privateBathroom)) {
            $0.editingFilter.toggleOption(.privateBathroom)
        }
        await store.send(.filterApplyButtonTapped) {
            $0.appliedFilter = $0.editingFilter
            $0.appliedFilterSource = .manual
            $0.isFilterPresented = false
            $0.listingSource = .locationSearch
        }
        XCTAssertEqual(store.state.appliedFilter.monthlyRentRange.maximum, 50)
        XCTAssertEqual(store.state.appliedFilter.depositRange.maximum, 300)
        assertPriceQueries(
            store.state.appliedFilter.listingSearchInput(bounds: viewport.visibleBounds),
            equal: ["maxBudget": "500000"]
        )
        await store.finish()
    }

    func testPaginationKeepsAppliedSelectedCaps() async {
        let requests = LockIsolated<[ListingSearchInput]>([])
        var state = MapFeature.State()
        state.appliedFilter = boundedFilter
        state.listingSource = .locationSearch
        state.lastSearchedViewport = viewport
        state.listingPageInfo = PageInfo(number: 0, size: 10, totalElements: 11, totalPages: 2, hasNext: true)
        state.listings = [ListingItemModel(
            id: "last-listing", formattedPrice: "", formattedUsdPrice: "", detailsDescription: "",
            locationDescription: "", typeTag: "", period: "", isLiked: false
        )]
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.listingClient.fetchListings = { @MainActor input in
                requests.withValue { $0.append(input) }
                return ListingSearchPage(content: [], page: nil)
            }
        }
        await store.send(.listingRowAppeared("last-listing")) { $0.isListingSearchLoading = true }
        await store.receive(\.listingSearchResponse) {
            $0.isListingSearchLoading = false
            $0.listingPageInfo = nil
            $0.listings = []
        }
        XCTAssertEqual(requests.value.count, 1)
        for input in requests.value {
            XCTAssertEqual(input.page, 1)
            assertPriceQueries(input, equal: ["maxBudget": "500000", "maxDeposit": "1500000"])
        }
        await store.finish()
    }

    private var boundedFilter: MapFilterState {
        var filter = MapFilterState()
        filter.updateMonthlyRentMaximum(50)
        filter.updateDepositMaximum(150)
        return filter
    }

    private var viewport: MapViewport {
        MapViewport(
            center: MapCoordinate(latitude: 37.55, longitude: 126.92), zoomLevel: 14,
            visibleBounds: MapBounds(
                southWest: MapCoordinate(latitude: 37.54, longitude: 126.91),
                northEast: MapCoordinate(latitude: 37.56, longitude: 126.93)
            )
        )
    }

    private func makeSearchStore(
        _ state: MapFeature.State,
        _ listRequests: LockIsolated<[ListingSearchInput]>,
        _ markerRequests: LockIsolated<[ListingSearchInput]>,
        _ clock: TestClock<Duration>
    ) -> TestStoreOf<MapFeature> {
        TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.listingClient.fetchListings = { @MainActor input in
                listRequests.withValue { $0.append(input) }
                return ListingSearchPage(content: [], page: nil)
            }
            $0.listingClient.fetchMapMarkers = { @MainActor input in
                markerRequests.withValue { $0.append(input) }
                try await clock.sleep(for: .milliseconds(1))
                return []
            }
        }
    }

    private func receiveSearch(_ store: TestStoreOf<MapFeature>, _ clock: TestClock<Duration>) async {
        await store.receive(\.listingSearchResponse) { $0.isListingSearchLoading = false }
        await clock.advance(by: .milliseconds(1))
        await store.receive(\.listingMapMarkersResponse)
    }

    private func assertPriceQueries(
        _ input: ListingSearchInput,
        equal expected: [String: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let priceKeys = ["minBudget", "maxBudget", "minDeposit", "maxDeposit"]
        for query in [ListingListQueryDTO(input).queryItems, ListingMapQueryDTO(input).queryItems] {
            let prices = Dictionary(uniqueKeysWithValues: query
                .filter { priceKeys.contains($0.name) }
                .map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(prices, expected, file: file, line: line)
        }
    }

    private func priceChip(_ filter: MapFilterState, _ language: AppLanguage) throws -> MapListingFilterChipItem {
        try XCTUnwrap(MapListingFilterChipItem.items(for: filter, source: .manual, locale: language.locale)
            .first { $0.kind == .price })
    }
}
