//
//  MapFeature+State.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture
import Foundation

extension MapFeature {
    @ObservableState
    struct State: Equatable {
        // Navigation
        var path = StackState<Path.State>()
        var userType: UserType?
        var appLanguage: AppLanguage = .english

        // 현재 검색 모드 / 화면 표시
        // - searchMode(listingSource): 목록과 마커를 어느 API 결과로 채우는지 정한다. (위치 검색 / 진단 추천)
        //   모드별 데이터는 연관값에 있다. 아래 확장의 같은 이름 프로퍼티는 호출부 호환용 접근자다.
        // - appliedFilterSource: 적용된 필터가 진단 조건인지 나타낸다. 필터 칩과 진단 버튼 표시에만 쓴다.
        // 가능한 조합
        // - idle + manual: 지도 첫 진입 전
        // - locationSearch + manual: 일반 검색
        // - locationSearch + diagnosis: 진단 중 재검색하거나, 필터를 바꾸지 않고 적용한 경우
        // - diagnosis + diagnosis: 진단으로 막 진입한 경우
        // diagnosis + manual 조합은 나오면 안 된다. 두 값은 beginLocationSearch와 beginDiagnosisSearch에서 함께 바꾼다.
        var searchMode: MapSearchMode = .idle
        var appliedFilterSource: MapFilterApplicationSource = .manual
        var markers: [MapMarkerItem] = []
        var selectedMarkerID: String?

        // 목록 밖 마커에서 필터를 적용해 조회한 카드 원본. 현재 선택 동안만 보관한다.
        var selectedListing: Listing?
        var selectedListingRequestID: UUID?

        // 지도 viewport / 카메라 요청
        var currentViewport: MapViewport?
        var viewportSearchTrigger: MapViewportSearchTrigger = .onFirstIdle
        var selectedPlaceSearchTitle: String?
        var showsResearchButton = false
        var cameraMoveRequest: MapCameraMoveRequest?

        // 바텀시트 / 필터
        var sheetMode: MapSheetMode = .listingList
        var isFilterPresented = false
        var appliedFilter = MapFilterState()
        var editingFilter = MapFilterState()

        // 즐겨찾기 / 환율
        var favoriteUpdatingIDs: Set<String> = []
        var favoriteStatusesByListingID: [String: ListingFavoriteStatus] = [:]
        var favoriteErrorMessage: String?
        var krwToUSDExchangeRate: KRWToUSDExchangeRate?

        // 진단 버튼
        var isDiagnosisButtonExpanded = false
        var isDiagnosisMatchesButtonExpanded = true
    }

    @CasePathable
    enum Action {
        // Lifecycle
        case mapAppeared
        case mapDismissed

        // 일반 매물 검색
        case initialLocationSearchRequested
        case browseListingsRequested
        case listingSearchResponse(Result<ListingSearchPage, Error>, isFirstPage: Bool)
        case listingMapMarkersResponse(Result<[ListingMapMarker], Error>)
        case placeSearchResultSelected(SearchPlaceResult)
        case listingMapPreviewRequested(MapCoordinate)
        case placeSearchDisplayClearButtonTapped
        case researchButtonTapped
        case listingRowAppeared(String)

        // 진단 추천 검색
        case diagnosisButtonTapped
        case diagnosisButtonCloseButtonTapped
        case diagnosisButtonAutoCollapseDelayFinished
        case diagnosisResultRequested(diagnosisID: Int, filter: MapFilterState)
        case diagnosisDetailResponse(Result<DiagnosisDetail, Error>)
        case diagnosisRecommendationsResponse(Result<DiagnosisRecommendations, Error>, isFirstPage: Bool)
        case diagnosisMapResponse(requestID: UUID, Result<DiagnosisRecommendationMap, DataError>)

        // 지도 viewport / 카메라
        case viewportChanged(MapViewport)
        case cameraMoveRequestHandled

        // 환율
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, Error>)

        // 매물 선택 / Navigation
        case markerTapped(String)
        case selectedListingResponse(requestID: UUID, Result<Listing, DataError>)
        case popupRequested(AppPopup)
        case searchButtonTapped
        case path(StackActionOf<Path>)
        case listingCardTapped(String)
        case selectedListingCardTapped
        case selectedListingCloseButtonTapped

        // 즐겨찾기
        case listingLikeButtonTapped(String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)

        // 필터
        case filterButtonTapped
        case filterDismissed
        case filterOptionTapped(RoomCondition)
        case filterPropertyTypeTapped(MapPropertyType)
        case monthlyRentMinimumChanged(Int)
        case monthlyRentMaximumChanged(Int)
        case depositMinimumChanged(Int)
        case depositMaximumChanged(Int)
        case filterApplyButtonTapped
        case filterResetButtonTapped
    }
}

extension MapFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }

    var showsFavoriteControls: Bool {
        userType != .landlord
    }
}

// MARK: - 검색 모드 접근자

extension MapFeature.State {
    /// 현재 모드의 종류. 다른 모드로 바꾸면 새 모드는 빈 데이터로 시작하고, 이전 모드 데이터는 사라진다.
    var listingSource: MapListingSource {
        get {
            switch searchMode {
            case .idle: .idle
            case .locationSearch: .locationSearch
            case .diagnosis: .diagnosis
            }
        }
        set {
            guard newValue != listingSource else { return }
            switch newValue {
            case .idle: searchMode = .idle
            case .locationSearch: searchMode = .locationSearch(MapLocationSearchState())
            case .diagnosis: searchMode = .diagnosis(MapDiagnosisSearchState())
            }
        }
    }

    /// 화면용 카드 목록. 현재 모드의 원본에 환율·언어·찜 상태를 입혀 매번 계산한다.
    var listings: [ListingItemModel] {
        // 순수 계산이라 의존성 주입 없이 live 구현을 쓴다. (State 계산 프로퍼티에서는 리듀서 의존성에 접근할 수 없다)
        let convertCurrency = ConvertMonthlyRentCurrencyUseCase.liveValue
        var items: [ListingItemModel]
        switch searchMode {
        case .idle:
            return []
        case let .locationSearch(search):
            items = search.results.map {
                ListingItemModel(
                    listing: $0,
                    exchangeRate: krwToUSDExchangeRate,
                    convertMonthlyRentCurrencyUseCase: convertCurrency,
                    language: appLanguage
                )
            }
        case let .diagnosis(diagnosis):
            items = diagnosis.recommendations.map {
                ListingItemModel(
                    recommendation: $0,
                    exchangeRate: krwToUSDExchangeRate,
                    convertMonthlyRentCurrencyUseCase: convertCurrency,
                    language: appLanguage
                )
            }
        }
        for index in items.indices {
            guard let status = favoriteStatusesByListingID[items[index].listingID] else { continue }
            items[index].isLiked = status.isFavorited
            items[index].favoriteCount = status.favoriteCount
        }
        return items
    }

    // 아래는 기존 필드 이름을 유지하는 호환용 접근자다. 해당 모드가 아니면 읽을 때 기본값을 돌려주고, 쓸 때는 무시한다.
    // 호출부를 `searchMode` 패턴 매칭으로 옮기면 제거한다.

    private var locationSearch: MapLocationSearchState? {
        if case let .locationSearch(search) = searchMode { search } else { nil }
    }

    private var diagnosisSearch: MapDiagnosisSearchState? {
        if case let .diagnosis(diagnosis) = searchMode { diagnosis } else { nil }
    }

    private mutating func updateLocationSearch(_ update: (inout MapLocationSearchState) -> Void) {
        guard case var .locationSearch(search) = searchMode else { return }
        update(&search)
        searchMode = .locationSearch(search)
    }

    private mutating func updateDiagnosisSearch(_ update: (inout MapDiagnosisSearchState) -> Void) {
        guard case var .diagnosis(diagnosis) = searchMode else { return }
        update(&diagnosis)
        searchMode = .diagnosis(diagnosis)
    }

    var listingSearchResults: [Listing] {
        get { locationSearch?.results ?? [] }
        set { updateLocationSearch { $0.results = newValue } }
    }

    var listingPageInfo: PageInfo? {
        get { locationSearch?.pageInfo }
        set { updateLocationSearch { $0.pageInfo = newValue } }
    }

    var isListingSearchLoading: Bool {
        get { locationSearch?.isLoading ?? false }
        set { updateLocationSearch { $0.isLoading = newValue } }
    }

    var listingSearchErrorMessage: String? {
        get { locationSearch?.errorMessage }
        set { updateLocationSearch { $0.errorMessage = newValue } }
    }

    var activeDiagnosisID: Int? {
        get { diagnosisSearch?.diagnosisID }
        set { updateDiagnosisSearch { $0.diagnosisID = newValue } }
    }

    var diagnosisRecommendedListings: [DiagnosisRecommendedListing] {
        get { diagnosisSearch?.recommendations ?? [] }
        set { updateDiagnosisSearch { $0.recommendations = newValue } }
    }

    var diagnosisRecommendationPageInfo: PageInfo? {
        get { diagnosisSearch?.pageInfo }
        set { updateDiagnosisSearch { $0.pageInfo = newValue } }
    }

    var isRecommendationsLoading: Bool {
        get { diagnosisSearch?.isRecommendationsLoading ?? false }
        set { updateDiagnosisSearch { $0.isRecommendationsLoading = newValue } }
    }

    var recommendationsErrorMessage: String? {
        get { diagnosisSearch?.recommendationsErrorMessage }
        set { updateDiagnosisSearch { $0.recommendationsErrorMessage = newValue } }
    }

    var diagnosisMapRequestID: UUID? {
        get { diagnosisSearch?.mapRequestID }
        set { updateDiagnosisSearch { $0.mapRequestID = newValue } }
    }

    var diagnosisMapTotal: Int? {
        get { diagnosisSearch?.mapTotal }
        set { updateDiagnosisSearch { $0.mapTotal = newValue } }
    }

    var diagnosisMapErrorMessage: String? {
        get { diagnosisSearch?.mapErrorMessage }
        set { updateDiagnosisSearch { $0.mapErrorMessage = newValue } }
    }

    var isDiagnosisDetailLoading: Bool {
        get { diagnosisSearch?.isDetailLoading ?? false }
        set { updateDiagnosisSearch { $0.isDetailLoading = newValue } }
    }

    var diagnosisErrorMessage: String? {
        get { diagnosisSearch?.detailErrorMessage }
        set { updateDiagnosisSearch { $0.detailErrorMessage = newValue } }
    }
}
