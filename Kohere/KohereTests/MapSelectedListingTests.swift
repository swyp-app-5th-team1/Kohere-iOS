import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class MapSelectedListingTests: XCTestCase {
    func testLoadedMarkerUsesListWithoutFetchingAgain() async {
        let item = ListingItemModel(listing: makeMarkerListing(), language: .english)
        var state = MapFeature.State()
        state.listings = [item]
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.listingClient.fetchListings = { _ in
                XCTFail("목록에 있는 마커는 다시 조회하지 않는다")
                return ListingSearchPage(content: [], page: nil)
            }
            $0.listingClient.fetchDetail = { _ in
                XCTFail("마커 선택에서는 상세를 미리 조회하지 않는다")
                return makeMarkerDetail()
            }
        }
        await store.send(.markerTapped(item.listingID)) {
            $0.selectedMarkerID = item.listingID
            $0.sheetMode = .selectedListing
        }
        XCTAssertEqual(store.state.selectedListingItem, item)
        XCTAssertNil(store.state.selectedListing)
        await store.finish()
    }

    func testMissingMarkerUsesIDsAndAppliedFiltersWithoutReplacingListOrPagination() async throws {
        let listing = makeMarkerListing()
        let other = makeMarkerListing(id: "other")
        let requestID = UUID()
        let requests = LockIsolated<[ListingSearchInput]>([])
        let rate = KRWToUSDExchangeRate(usdPerKRW: 0.001)
        let pageInfo = PageInfo(number: 2, size: 10, totalElements: 40, totalPages: 4, hasNext: true)
        var state = MapFeature.State()
        state.listingSource = .locationSearch
        state.krwToUSDExchangeRate = rate
        state.listings = [ListingItemModel(listing: other, language: .english)]
        state.listingSearchResults = [other]
        state.listingPageInfo = pageInfo
        state.appliedFilter.updateMonthlyRentMaximum(50)
        state.appliedFilter.updateDepositMaximum(150)
        state.appliedFilter.selectedOptions = [.privateBathroom]
        state.appliedFilter.selectedPropertyTypes = [.goshiwon]
        // 아직 적용하지 않은 초안은 마커 조회에 영향을 주지 않는다.
        state.editingFilter.updateMonthlyRentMaximum(30)
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
            $0.listingClient.fetchListings = { @MainActor input in
                requests.withValue { $0.append(input) }
                return ListingSearchPage(content: [listing], page: nil)
            }
            $0.listingClient.fetchDetail = { _ in
                XCTFail("선택 카드 조회는 listings API만 사용한다")
                return makeMarkerDetail()
            }
        }
        await store.send(.markerTapped(listing.listingID)) {
            $0.selectedMarkerID = listing.listingID
            $0.sheetMode = .selectedListing
            $0.selectedListingRequestID = requestID
        }
        await store.receive(\.selectedListingResponse) {
            $0.selectedListingRequestID = nil
            $0.selectedListing = listing
        }
        await store.send(.markerTapped(listing.listingID))
        XCTAssertEqual(requests.value.count, 1)
        let input = try XCTUnwrap(requests.value.first)
        XCTAssertEqual(input.listingIDs, [listing.listingID])
        XCTAssertNil(input.bounds)
        XCTAssertEqual(input.page, 0)
        XCTAssertEqual(input.size, 1)
        XCTAssertEqual(input.maxBudget, 500_000)
        XCTAssertEqual(input.maxDeposit, 1_500_000)
        XCTAssertEqual(input.conditions, [.privateBathroom])
        XCTAssertEqual(input.propertyTypes, [.goshiwon])
        XCTAssertEqual(store.state.listings, state.listings)
        XCTAssertEqual(store.state.listingSearchResults, [other])
        XCTAssertEqual(store.state.listingPageInfo, pageInfo)
        let item = try XCTUnwrap(selectedItem(from: store.state))
        XCTAssertEqual(item.title, listing.title)
        XCTAssertEqual(item.thumbnailURL, listing.thumbnailURL)
        XCTAssertEqual(item.formattedPrice, MonthlyRentPriceFormatter.wonTitle(
            min: 380_000, max: 400_000, language: .english
        ))
        XCTAssertFalse(item.formattedUsdPrice.isEmpty)

        // 카드는 요약 정보다. 상세 화면은 ID로 들어가서 상세를 새로 조회한다.
        store.exhaustivity = .off
        await store.send(.selectedListingCardTapped)
        let destination = try XCTUnwrap(store.state.path.last?.listingDetail)
        XCTAssertEqual(destination.listingID, listing.listingID)
        XCTAssertNil(destination.listingDetail)
        XCTAssertNil(destination.detail)
        XCTAssertFalse(destination.isDetailLoaded)
        await store.finish()
    }

    func testCloseCancelsPendingRequestAndLateResponseCannotReopenCard() async {
        let listing = makeMarkerListing()
        let requestID = UUID()
        let clock = TestClock()
        let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.listingClient.fetchListings = { _ in
                try await clock.sleep(for: .seconds(1))
                return ListingSearchPage(content: [listing], page: nil)
            }
        }
        await store.send(.markerTapped(listing.listingID)) {
            $0.selectedMarkerID = listing.listingID
            $0.sheetMode = .selectedListing
            $0.selectedListingRequestID = requestID
        }
        await store.send(.selectedListingCloseButtonTapped) {
            $0.selectedMarkerID = nil
            $0.sheetMode = .listingList
            $0.selectedListingRequestID = nil
        }
        await clock.advance(by: .seconds(1))
        await store.send(.selectedListingResponse(requestID: requestID, .success(listing)))
        await store.finish()
    }

    func testDiagnosisMarkerUsesAppliedFiltersWithoutChangingSearchMode() async throws {
        let listing = makeMarkerListing()
        let requestID = UUID()
        let requests = LockIsolated<[ListingSearchInput]>([])
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 42
        state.appliedFilterSource = .diagnosis
        state.appliedFilter.updateMonthlyRentMaximum(50)
        state.appliedFilter.selectedOptions = [.privateBathroom, .englishSupport]
        state.editingFilter.updateMonthlyRentMaximum(30)
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.listingClient.fetchListings = { input in
                requests.withValue { $0.append(input) }
                return ListingSearchPage(content: [listing], page: nil)
            }
        }
        store.exhaustivity = .off
        await store.send(.markerTapped(listing.listingID))
        await store.receive(\.selectedListingResponse)
        let input = try XCTUnwrap(requests.value.first)
        XCTAssertEqual(input.listingIDs, [listing.listingID])
        XCTAssertEqual(input.maxBudget, 500_000)
        XCTAssertEqual(Set(input.conditions), state.appliedFilter.selectedOptions)
        XCTAssertNil(input.bounds)
        XCTAssertNil(input.maxDeposit)
        XCTAssertEqual(store.state.appliedFilter, state.appliedFilter)
        XCTAssertEqual(store.state.editingFilter, state.editingFilter)
        XCTAssertEqual(store.state.listingSource, .diagnosis)
        XCTAssertEqual(store.state.appliedFilterSource, .diagnosis)
        XCTAssertEqual(store.state.activeDiagnosisID, 42)
        await store.finish()
    }

    func testLateDiagnosisDetailReloadsCardWithCorrectedFilter() async throws {
        let listing = makeMarkerListing()
        let clock = TestClock()
        let oldRequestID = UUID()
        let newRequestID = UUID()
        let requests = LockIsolated<[ListingSearchInput]>([])
        var state = MapFeature.State()
        state.listingSource = .diagnosis
        state.activeDiagnosisID = 42
        state.appliedFilterSource = .diagnosis
        state.selectedMarkerID = listing.listingID
        state.selectedListingRequestID = oldRequestID
        state.sheetMode = .selectedListing
        state.isDiagnosisDetailLoading = true
        let detail = DiagnosisDetail(
            diagnosisID: 42, region: "SEOUL", purpose: "STUDY", university: nil, district: nil,
            conditions: [.privateBathroom], monthlyRentMin: 0, monthlyRentMax: 500_000,
            arcStatus: "YES", status: "COMPLETED", submittedAt: "2026-09-10"
        )
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.uuid = .constant(newRequestID)
            $0.listingClient.fetchListings = { input in
                requests.withValue { $0.append(input) }
                try await clock.sleep(for: .seconds(1))
                return ListingSearchPage(content: [listing], page: nil)
            }
        }
        store.exhaustivity = .off
        await store.send(.diagnosisDetailResponse(.success(detail)))
        XCTAssertEqual(store.state.selectedListingRequestID, newRequestID)
        await store.send(.selectedListingResponse(requestID: oldRequestID, .failure(.emptyResponse)))
        await clock.advance(by: .seconds(1))
        await store.receive(\.selectedListingResponse)
        let input = try XCTUnwrap(requests.value.first)
        XCTAssertEqual(input.maxBudget, 500_000)
        XCTAssertEqual(input.conditions, [.privateBathroom])
        XCTAssertEqual(store.state.selectedListing, listing)
        XCTAssertFalse(store.state.isDiagnosisDetailLoading)
        await store.finish()
    }

    func testSwitchToLoadedMarkerCancelsPendingCardRequest() async {
        let listing = makeMarkerListing()
        let other = ListingItemModel(listing: makeMarkerListing(id: "other"), language: .english)
        let requestID = UUID()
        let clock = TestClock()
        var state = MapFeature.State()
        state.listings = [other]
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.listingClient.fetchListings = { _ in
                try await clock.sleep(for: .seconds(1))
                return ListingSearchPage(content: [listing], page: nil)
            }
        }
        await store.send(.markerTapped(listing.listingID)) {
            $0.selectedMarkerID = listing.listingID
            $0.selectedListingRequestID = requestID
            $0.sheetMode = .selectedListing
        }
        await store.send(.markerTapped(other.listingID)) {
            $0.selectedMarkerID = other.listingID
            $0.selectedListingRequestID = nil
        }
        await clock.advance(by: .seconds(1))
        await store.send(.selectedListingResponse(requestID: requestID, .success(listing)))
        XCTAssertEqual(store.state.selectedListingItem, other)
        await store.finish()
    }

    func testListArrivingDuringMarkerRequestDoesNotEnableDetailNavigation() async {
        let listing = makeMarkerListing()
        var state = MapFeature.State()
        state.selectedMarkerID = listing.listingID
        state.selectedListingRequestID = UUID()
        state.sheetMode = .selectedListing
        state.listings = [ListingItemModel(listing: listing, language: .english)]
        let store = TestStore(initialState: state) { MapFeature() }
        XCTAssertNil(store.state.selectedListingItem)
        await store.send(.selectedListingCardTapped)
        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testPreviousRequestForSameMarkerCannotOverwriteNewRequestOrShowError() async {
        let listing = makeMarkerListing()
        let oldRequestID = UUID()
        let currentRequestID = UUID()
        var state = MapFeature.State()
        state.selectedMarkerID = listing.listingID
        state.sheetMode = .selectedListing
        state.selectedListingRequestID = currentRequestID
        let store = TestStore(initialState: state) { MapFeature() }
        await store.send(.selectedListingResponse(requestID: oldRequestID, .success(listing)))
        await store.send(.selectedListingResponse(requestID: oldRequestID, .failure(.emptyResponse)))
        XCTAssertNil(store.state.selectedListing)
        XCTAssertEqual(store.state.selectedListingRequestID, currentRequestID)
    }

    func testBrowseClearsSelectedCardAndInvalidatesPendingResponse() async {
        let listing = makeMarkerListing()
        let requestID = UUID()
        var state = MapFeature.State()
        state.listingSource = .locationSearch
        state.selectedMarkerID = listing.listingID
        state.selectedListing = listing
        state.selectedListingRequestID = requestID
        state.sheetMode = .selectedListing
        let store = TestStore(initialState: state) { MapFeature() }
        await store.send(.browseListingsRequested) {
            $0.selectedMarkerID = nil
            $0.selectedListing = nil
            $0.selectedListingRequestID = nil
            $0.sheetMode = .listingList
        }
        await store.send(.selectedListingResponse(requestID: requestID, .success(listing)))
    }

    func testResponseMatchesListingIDInsteadOfTakingFirstCard() async {
        let listing = makeMarkerListing()
        let requestID = UUID()
        let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.listingClient.fetchListings = { _ in
                ListingSearchPage(content: [makeMarkerListing(id: "other"), listing], page: nil)
            }
        }
        await store.send(.markerTapped(listing.listingID)) {
            $0.selectedMarkerID = listing.listingID
            $0.selectedListingRequestID = requestID
            $0.sheetMode = .selectedListing
        }
        await store.receive(\.selectedListingResponse) {
            $0.selectedListingRequestID = nil
            $0.selectedListing = listing
        }
        await store.finish()
    }

    func testEmptyOrMismatchedResponseRestoresListAndRequestsNotice() async {
        for content in [[], [makeMarkerListing(id: "other")]] {
            let requestID = UUID()
            let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
                $0.uuid = .constant(requestID)
                $0.listingClient.fetchListings = { _ in ListingSearchPage(content: content, page: nil) }
                $0.listingClient.fetchDetail = { _ in
                    XCTFail("빈 응답이어도 상세 API로 우회하지 않는다")
                    return makeMarkerDetail()
                }
            }
            await store.send(.markerTapped("missing")) {
                $0.selectedMarkerID = "missing"
                $0.selectedListingRequestID = requestID
                $0.sheetMode = .selectedListing
            }
            await store.receive(\.selectedListingResponse) {
                $0.selectedMarkerID = nil
                $0.selectedListingRequestID = nil
                $0.sheetMode = .listingList
            }
            await store.receive(\.popupRequested)
            await store.finish()
        }
    }

    func testFetchFailureRestoresListAndRequestsNotice() async {
        let requestID = UUID()
        let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
            $0.uuid = .constant(requestID)
            $0.listingClient.fetchListings = { _ in throw DataError.emptyResponse }
        }
        await store.send(.markerTapped("missing")) {
            $0.selectedMarkerID = "missing"
            $0.selectedListingRequestID = requestID
            $0.sheetMode = .selectedListing
        }
        await store.receive(\.selectedListingResponse) {
            $0.selectedMarkerID = nil
            $0.selectedListingRequestID = nil
            $0.sheetMode = .listingList
        }
        await store.receive(\.popupRequested)
        await store.finish()
    }

    func testFavoriteOnMarkerOutsideListUpdatesCardBeforeDetailNavigation() async throws {
        let listing = makeMarkerListing()
        let status = ListingFavoriteStatus(isFavorited: true, favoriteCount: 7)
        let clock = TestClock()
        var state = MapFeature.State()
        state.userType = .tenant
        state.selectedMarkerID = listing.listingID
        state.selectedListing = listing
        state.sheetMode = .selectedListing
        let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
            $0.listingClient.addFavorite = { _ in
                try await clock.sleep(for: .seconds(1))
                return status
            }
        }
        await store.send(.listingLikeButtonTapped(listing.listingID)) {
            $0.favoriteUpdatingIDs = [listing.listingID]
        }
        await store.send(.selectedListingCardTapped)
        await clock.advance(by: .seconds(1))
        await store.receive(\.favoriteStatusResponse) {
            $0.favoriteUpdatingIDs = []
            $0.favoriteStatusesByListingID[listing.listingID] = status
        }
        XCTAssertEqual(selectedItem(from: store.state)?.isLiked, true)
        XCTAssertEqual(selectedItem(from: store.state)?.favoriteCount, 7)
        store.exhaustivity = .off
        await store.send(.selectedListingCardTapped)
        let destination = try XCTUnwrap(store.state.path.last?.listingDetail)
        XCTAssertEqual(destination.listingID, listing.listingID)
        XCTAssertFalse(destination.isDetailLoaded)
        await store.finish()
    }

    func testMapNoticeIsPresentedByRoot() async {
        let popup = AppPopup.notice(.init(message: "load failed", confirmTitle: "OK"))
        let store = TestStore(initialState: RootFeature.State(isAuthLoading: false)) { RootFeature() }
        await store.send(.map(.popupRequested(popup))) { $0.popup = popup }
    }
}

@MainActor
final class ListingQueryTests: XCTestCase {
    func testIDLookupEncodesRepeatedIDsAndFiltersWithoutViewport() throws {
        var filter = MapFilterState()
        filter.updateMonthlyRentMaximum(50)
        filter.updateDepositMaximum(150)
        filter.selectedOptions = [.privateBathroom]
        filter.selectedPropertyTypes = [.goshiwon]
        let ids = ["68e0000000000000000000a1", "68e0000000000000000000b1"]
        let input = filter.listingSearchInput(listingIDs: ids, size: 2)
        let request = try ListingRouter.list(
            query: ListingListQueryDTO(input), APIEnvironment(baseURL: URL(string: "https://example.com")!)
        ).asURLRequest()
        let url = try XCTUnwrap(request.url)
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(url.path, "/api/v2/listings")
        XCTAssertEqual(items.filter { $0.name == "listingIds" }.compactMap(\.value), ids)
        XCTAssertFalse(items.contains { ["swLat", "swLng", "neLat", "neLng"].contains($0.name) })
        for (key, value) in ["maxBudget": "500000", "maxDeposit": "1500000", "conditions": "PRIVATE_BATH",
                             "type": "GOSHIWON", "page": "0", "size": "2"] {
            XCTAssertEqual(items.first { $0.name == key }?.value, value)
        }
    }

    func testNormalSearchKeepsViewportAndOmitsEmptyIDs() {
        let bounds = MapBounds(
            southWest: .init(latitude: 37.54, longitude: 126.91),
            northEast: .init(latitude: 37.56, longitude: 126.93)
        )
        let input = MapFilterState().listingSearchInput(bounds: bounds)
        let listItems = ListingListQueryDTO(input).queryItems
        let mapItems = ListingMapQueryDTO(input).queryItems
        for items in [listItems, mapItems] {
            XCTAssertFalse(items.contains { $0.name == "listingIds" })
            XCTAssertEqual(items.first { $0.name == "swLat" }?.value, "37.54")
            XCTAssertEqual(items.first { $0.name == "swLng" }?.value, "126.91")
            XCTAssertEqual(items.first { $0.name == "neLat" }?.value, "37.56")
            XCTAssertEqual(items.first { $0.name == "neLng" }?.value, "126.93")
        }
        XCTAssertTrue(listItems.contains { $0.name == "page" })
        XCTAssertFalse(mapItems.contains { ["page", "size", "sort"].contains($0.name) })
    }

    func testMapQueryDoesNotSendListOnlyIDParameter() {
        let input = ListingSearchInput(
            bounds: MapBounds(
                southWest: .init(latitude: 37.54, longitude: 126.91),
                northEast: .init(latitude: 37.56, longitude: 126.93)
            ),
            listingIDs: ["68e0000000000000000000a1"], maxBudget: 500_000
        )
        let items = ListingMapQueryDTO(input).queryItems
        XCTAssertFalse(items.contains { $0.name == "listingIds" })
        XCTAssertEqual(items.first { $0.name == "maxBudget" }?.value, "500000")
    }
}

@MainActor
final class ListingDetailFetchTests: XCTestCase {
    func testDetailPageFetchesOnEntryAndDoesNotRepeatAfterLoading() async {
        let detail = makeMarkerDetail()
        let requestedIDs = LockIsolated<[String]>([])
        var state = ListingDetailFeature.State(listingID: detail.listingID)
        state.krwToUSDExchangeRate = .init(usdPerKRW: 0.001)
        let store = TestStore(initialState: state) { ListingDetailFeature() } withDependencies: {
            $0.fetchListingDetailUseCase.execute = { @MainActor id in
                requestedIDs.withValue { $0.append(id) }
                return detail
            }
            $0.convertMonthlyRentCurrencyUseCase = .liveValue
        }
        await store.send(.onAppear) { $0.isDetailLoading = true }
        store.exhaustivity = .off
        await store.receive(\.detailResponse)
        XCTAssertEqual(requestedIDs.value, [detail.listingID])
        XCTAssertEqual(store.state.listingDetail, detail)
        XCTAssertEqual(store.state.detail?.overview.title, detail.title)
        XCTAssertEqual(store.state.detail?.roomOffers.count, 2)
        XCTAssertTrue(store.state.isDetailLoaded)
        XCTAssertFalse(store.state.isDetailLoading)
        await store.send(.onAppear)
        XCTAssertEqual(requestedIDs.value.count, 1)
        await store.finish()
    }
}

@MainActor
private func selectedItem(from state: MapFeature.State) -> ListingItemModel? {
    withDependencies {
        $0.convertMonthlyRentCurrencyUseCase = .liveValue
    } operation: {
        state.selectedListingItem
    }
}

private func makeMarkerListing(id: String = "listing-1") -> Listing {
    Listing(
        listingID: id, title: "Marker home", type: "Goshiwon",
        minMonthlyRent: 380_000, maxMonthlyRent: 400_000,
        minDeposit: 300_000, maxDeposit: 500_000,
        minMaintenanceFee: 0, maxMaintenanceFee: 20_000,
        minStayMonths: 1, maxStayMonths: 12, thumbnailURL: "https://example.com/home.jpg",
        coordinate: .init(latitude: 37.55, longitude: 126.92), address: nil,
        nearestTransit: .init(type: "SUBWAY", name: "Hongik Univ. Station", walkMinutes: 5),
        distanceMeters: nil, isFavorited: false, favoriteCount: 6
    )
}

private func makeMarkerDetail() -> ListingDetail {
    ListingDetail(
        listingID: "listing-1", title: "Marker home", type: "Goshiwon", status: "ACTIVE",
        rentalType: "Monthly", refundPolicy: nil,
        contract: .init(minStayMonths: 1, maxStayMonths: 12), genderPolicy: nil,
        coordinate: .init(latitude: 37.55, longitude: 126.92), address: nil,
        nearestTransit: .init(type: "SUBWAY", name: "Hongik Univ. Station", walkMinutes: 5,
                              nearbyPlacesDescription: nil),
        nearbyUniversityCodes: [], building: nil, propertyPolicies: nil, facilities: nil,
        conditions: [],
        roomOffers: [500_000, 700_000].enumerated().map { index, rent in
            ListingDetailRoomOffer(
                id: "room-\(index)", name: "Room \(index)", status: "ACTIVE",
                pricing: .init(monthlyRent: rent, deposit: 1_000_000, maintenanceFee: 50_000, currency: "KRW"),
                inventory: nil, filterTags: [], roomImageURLs: []
            )
        },
        descriptions: nil, imageURLs: ["https://example.com/home.jpg"], isFavorited: false,
        favoriteCount: 6, createdAt: nil, updatedAt: nil
    )
}
