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
        // navigation
        var path = StackState<Path.State>()
        var userType: UserType?

        // 매물/마커 표시 상태
        var markers: [MapMarkerItem] = []
        var selectedMarkerID: String?
        var listings: [ListingItemModel] = []
        var listingSearchResults: [Listing] = []
        var diagnosisRecommendedListings: [DiagnosisRecommendedListing] = []
        var diagnosisRecommendationSuggestions: DiagnosisRecommendationSuggestions?
        var diagnosisRecommendationPageInfo: DiagnosisRecommendationPage?
        var favoriteUpdatingIDs: Set<String> = []
        var favoriteStatusesByListingID: [String: ListingFavoriteStatus] = [:]
        var favoriteErrorMessage: String?
        var listingSource: MapListingSource = .idle
        var krwToUSDExchangeRate: KRWToUSDExchangeRate?
        var isListingSearchLoading = false
        var listingSearchErrorMessage: String?
        var listingPageInfo: ListingSearchPageInfo?
        var isDiagnosisDetailLoading = false
        var isRecommendationsLoading = false
        var diagnosisErrorMessage: String?
        var recommendationsErrorMessage: String?

        // 지도 viewport / 재검색 상태
        var currentViewport: MapViewport?
        var lastSearchedViewport: MapViewport?
        var placeSearchTarget: MapPlaceSearchTarget?
        var showsResearchButton = false

        // 바텀시트 / 필터 상태
        var sheetMode: MapSheetMode = .listingList
        var isFilterPresented = false
        var appliedFilter = MapFilterState()
        var editingFilter = MapFilterState()
        var activeDiagnosisID: Int?
        var appliedFilterSource: MapFilterApplicationSource = .manual

        // 위치 권한 / 현재 위치 / 카메라 이동 요청 상태
        var locationAuthorization: MapLocationAuthorization = .notDetermined
        var userLocation: MapCoordinate?
        var cameraMoveRequest: MapCoordinate?
        var hasMovedToInitialUserLocation = false
        var isLocationPermissionDialogPresented = false
        var isDiagnosisButtonExpanded = false
        var isDiagnosisMatchesButtonExpanded = true
    }

    @CasePathable
    enum Action {
        case mapAppeared
        case mapDismissed
        case locationAuthorizationChanged(MapLocationAuthorization)
        case userLocationUpdated(MapCoordinate)
        case myLocationButtonTapped
        case diagnosisButtonTapped
        case diagnosisButtonCloseButtonTapped
        case diagnosisButtonAutoCollapseDelayFinished
        case diagnosisResultRequested(diagnosisID: Int)
        case diagnosisDetailResponse(Result<DiagnosisDetail, Error>)
        case diagnosisRecommendationsResponse(Result<DiagnosisRecommendations, Error>)
        case locationSearchStarted
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, Error>)
        case listingSearchResponse(Result<ListingSearchPage, Error>)
        case locationPermissionDialogCloseButtonTapped
        case locationPermissionDialogSettingsButtonTapped
        case cameraMoveRequestHandled
        case markerTapped(String)
        case searchButtonTapped
        case placeSearchResultSelected(SearchPlaceResult)
        case researchButtonTapped
        case viewportChanged(MapViewport)
        case listingRowAppeared(String)
        case path(StackActionOf<Path>)
        case listingTapped(String)
        case listingLikeButtonTapped(String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)
        case selectedListingCardTapped
        case selectedListingCloseButtonTapped

        // 필터 관련
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

struct MapPlaceSearchTarget: Equatable {
    let coordinate: MapCoordinate
}

extension MapFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}
