//
//  MapFeature+State.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

extension MapFeature {
    @ObservableState
    struct State: Equatable {
        // Navigation
        var path = StackState<Path.State>()
        var userType: UserType?

        // 현재 검색 모드 / 화면 표시
        var listingSource: MapListingSource = .idle
        var markers: [MapMarkerItem] = []
        var selectedMarkerID: String?
        var listings: [ListingItemModel] = []

        // 일반 매물 검색
        var listingSearchResults: [Listing] = []
        var isListingSearchLoading = false
        var listingSearchErrorMessage: String?
        var listingPageInfo: ListingSearchPageInfo?

        // 진단 추천 검색
        var activeDiagnosisID: Int?
        var diagnosisRecommendedListings: [DiagnosisRecommendedListing] = []
        var diagnosisRecommendationSuggestions: DiagnosisRecommendationSuggestions?
        var diagnosisRecommendationPageInfo: DiagnosisRecommendationPage?
        var isDiagnosisDetailLoading = false
        var isRecommendationsLoading = false
        var diagnosisErrorMessage: String?
        var recommendationsErrorMessage: String?

        // 지도 viewport / 카메라 요청
        var currentViewport: MapViewport?
        var lastSearchedViewport: MapViewport?
        var pendingViewportSearchTarget: MapPendingViewportSearchTarget?
        var selectedPlaceSearchTitle: String?
        var showsResearchButton = false
        var cameraMoveRequest: MapCameraMoveRequest?

        // 바텀시트 / 필터
        var sheetMode: MapSheetMode = .listingList
        var isFilterPresented = false
        var appliedFilter = MapFilterState()
        var editingFilter = MapFilterState()
        var appliedFilterSource: MapFilterApplicationSource = .manual

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
        case listingSearchResponse(Result<ListingSearchPage, Error>)
        case placeSearchResultSelected(SearchPlaceResult)
        case listingMapPreviewRequested(MapCoordinate)
        case placeSearchDisplayClearButtonTapped
        case researchButtonTapped
        case listingRowAppeared(String)

        // 진단 추천 검색
        case diagnosisButtonTapped
        case diagnosisButtonCloseButtonTapped
        case diagnosisButtonAutoCollapseDelayFinished
        case diagnosisResultRequested(diagnosisID: Int)
        case diagnosisDetailResponse(Result<DiagnosisDetail, Error>)
        case diagnosisRecommendationsResponse(Result<DiagnosisRecommendations, Error>)

        // 지도 viewport / 카메라
        case viewportChanged(MapViewport)
        case cameraMoveRequestHandled

        // 환율
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, Error>)

        // 매물 선택 / Navigation
        case markerTapped(String)
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

struct MapPendingViewportSearchTarget: Equatable {
    let coordinate: MapCoordinate
}

extension MapFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}
