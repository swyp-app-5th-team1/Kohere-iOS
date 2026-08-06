//
//  MapFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MapFeature {
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient
    @Dependency(\.listingClient)
    var listingClient
    @Dependency(\.diagnosisClient)
    var diagnosisClient
    @Dependency(\.fetchKRWToUSDExchangeRateUseCase)
    var fetchKRWToUSDExchangeRateUseCase
    @Dependency(\.convertMonthlyRentCurrencyUseCase)
    var convertMonthlyRentCurrencyUseCase

    @Reducer
    enum Path {
        case listingDetail(ListingDetailFeature)
        case listingApplication(ListingApplicationFeature)
        case listingApplicationPrivacyWeb(ListingApplicationPrivacyWebFeature)
        case chatBot(ChatBotFeature)
        case search(SearchFeature)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Lifecycle
            case .mapAppeared:
                return handleMapAppeared(state: &state)

            case .mapDismissed:
                return handleMapDismissed(state: &state)

            // 일반 매물 검색
            case .initialLocationSearchRequested:
                return beginLocationSearch(.initialEntry, state: &state)

            case .browseListingsRequested:
                return beginLocationSearch(.browseListings, state: &state)

            case let .placeSearchResultSelected(placeResult):
                return beginLocationSearch(.placeResult(placeResult), state: &state)

            case let .listingMapPreviewRequested(coordinate):
                return beginLocationSearch(.listingPreview(coordinate), state: &state)

            case .researchButtonTapped:
                return beginLocationSearch(.researchCurrentViewport, state: &state)

            case let .listingSearchResponse(result, isFirstPage):
                return handleListingSearchResponse(result, isFirstPage: isFirstPage, state: &state)

            case let .listingRowAppeared(listingID):
                return handleListingRowAppeared(listingID, state: &state)

            case .placeSearchDisplayClearButtonTapped:
                state.selectedPlaceSearchTitle = nil
                return .none

            // 진단 추천 검색
            case let .diagnosisResultRequested(diagnosisID, filter):
                return beginDiagnosisSearch(
                    diagnosisID: diagnosisID,
                    filter: filter,
                    state: &state
                )

            case let .diagnosisDetailResponse(result):
                return handleDiagnosisDetailResponse(result, state: &state)

            case let .diagnosisRecommendationsResponse(result, isFirstPage):
                return handleDiagnosisRecommendationsResponse(
                    result,
                    isFirstPage: isFirstPage,
                    state: &state
                )

            case .diagnosisButtonTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none

            case .diagnosisButtonCloseButtonTapped:
                state.isDiagnosisMatchesButtonExpanded = false
                return .none

            case .diagnosisButtonAutoCollapseDelayFinished:
                state.isDiagnosisButtonExpanded = false
                return .none

            // 지도 viewport / 카메라
            case let .viewportChanged(viewport):
                return handleViewportChanged(viewport, state: &state)

            case .cameraMoveRequestHandled:
                state.cameraMoveRequest = nil
                return .none

            // 매물 선택 / Navigation
            case let .markerTapped(id):
                guard state.selectedMarkerID != id else { return .none }
                state.selectedMarkerID = id
                state.sheetMode = .selectedListing
                return .none

            case .selectedListingCardTapped:
                guard let selectedMarkerID = state.selectedMarkerID else { return .none }
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: selectedMarkerID,
                            userType: state.userType,
                            appLanguage: state.appLanguage
                        )
                    )
                )
                return .none

            case .selectedListingCloseButtonTapped:
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                return .none

            case let .listingCardTapped(id):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: id,
                            userType: state.userType,
                            appLanguage: state.appLanguage
                        )
                    )
                )
                return .none

            case .searchButtonTapped:
                state.path.append(.search(SearchFeature.initialState(
                    userDefaultsClient: userDefaultsClient,
                    appLanguage: state.appLanguage
                )))
                return .none

            case let .path(pathAction):
                return handlePathAction(pathAction, state: &state)

            // 필터
            case .filterButtonTapped:
                state.editingFilter = state.appliedFilter
                state.isFilterPresented = true
                return .none

            case .filterDismissed:
                state.editingFilter = state.appliedFilter
                state.isFilterPresented = false
                return .none

            case let .filterOptionTapped(option):
                state.editingFilter.toggleOption(option)
                return .none

            case let .filterPropertyTypeTapped(property):
                state.editingFilter.togglePropertyType(property)
                return .none

            case let .monthlyRentMinimumChanged(minimum):
                state.editingFilter.updateMonthlyRentMinimum(minimum)
                return .none

            case let .monthlyRentMaximumChanged(maximum):
                state.editingFilter.updateMonthlyRentMaximum(maximum)
                return .none

            case let .depositMinimumChanged(minimum):
                state.editingFilter.updateDepositMinimum(minimum)
                return .none

            case let .depositMaximumChanged(maximum):
                state.editingFilter.updateDepositMaximum(maximum)
                return .none

            case .filterApplyButtonTapped:
                return handleFilterApplyButtonTapped(state: &state)

            case .filterResetButtonTapped:
                state.editingFilter = MapFilterState()
                return .none

            // 즐겨찾기 / 환율
            case let .listingLikeButtonTapped(listingID):
                return startFavoriteUpdateEffect(listingID: listingID, state: &state)

            case let .favoriteStatusResponse(listingID, result):
                return handleFavoriteStatusResponse(listingID: listingID, result: result, state: &state)

            case let .exchangeRateResponse(.success(exchangeRate)):
                applyExchangeRate(exchangeRate, to: &state)
                return .none

            case .exchangeRateResponse(.failure):
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MapFeature.Path.State: Equatable {}
