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
    @Dependency(\.locationClient)
    var locationClient
    @Dependency(\.settingsClient)
    var settingsClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient
    @Dependency(\.diagnosisClient)
    var diagnosisClient

    @Reducer
    enum Path {
        case listingDetail(ListingDetailFeature)
        case chatBot(ChatBotFeature)
    }

    @ObservableState
    struct State: Equatable {
        // navigation
        var path = StackState<Path.State>()

        // 매물/마커 표시 상태
        var markers: [MapMarkerItem] = []
        var selectedMarkerID: String?
        var listings: [ListingItemModel] = []
        var listingSource: MapListingSource = .idle
        var isDiagnosisDetailLoading = false
        var isRecommendationsLoading = false
        var diagnosisErrorMessage: String?
        var recommendationsErrorMessage: String?

        // 지도 viewport / 재검색 상태
        var currentViewport: MapViewport?
        var lastSearchedViewport: MapViewport?
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
        case locationPermissionDialogCloseButtonTapped
        case locationPermissionDialogSettingsButtonTapped
        case cameraMoveRequestHandled
        case markerTapped(String)
        case researchButtonTapped
        case viewportChanged(MapViewport)
        case path(StackActionOf<Path>)
        case listingTapped(String)
        case listingLikeButtonTapped(String)
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

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .mapAppeared:
                var effects: [Effect<Action>] = [
                    .run { [locationClient] send in
                        let authorization = await locationClient.requestAuthorization()
                        await send(.locationAuthorizationChanged(authorization))

                        guard case .authorized = authorization else { return }

                        let updates = await locationClient.locationUpdates()
                        for await coordinate in updates {
                            await send(.userLocationUpdated(coordinate))
                        }
                    }
                    .cancellable(id: "MapFeature.locationUpdates", cancelInFlight: true)
                ]

                if state.appliedFilterSource != .diagnosis,
                   shouldExpandDiagnosisButtonToday(userDefaultsClient: userDefaultsClient) {
                    state.isDiagnosisButtonExpanded = true
                    effects.append(diagnosisButtonAutoCollapseEffect)
                }

                return .merge(effects)

            case .mapDismissed:
                state.isDiagnosisButtonExpanded = false
                return .merge(
                    .cancel(id: "MapFeature.locationUpdates"),
                    .cancel(id: "MapFeature.diagnosisButtonAutoCollapse"),
                    .cancel(id: "MapFeature.diagnosisDetail"),
                    .cancel(id: "MapFeature.diagnosisRecommendations")
                )

            case let .locationAuthorizationChanged(authorization):
                state.locationAuthorization = authorization

                switch authorization {
                case .authorized:
                    break

                case .notDetermined, .denied, .restricted:
                    state.userLocation = nil
                    state.hasMovedToInitialUserLocation = false
                }

                return .none

            case let .userLocationUpdated(coordinate):
                state.userLocation = coordinate

                if !state.hasMovedToInitialUserLocation {
                    state.cameraMoveRequest = coordinate
                    state.hasMovedToInitialUserLocation = true
                }

                return .none

            case .myLocationButtonTapped:
                switch state.locationAuthorization {
                case .authorized:
                    break

                case .denied, .restricted:
                    state.isLocationPermissionDialogPresented = true
                    return .none

                case .notDetermined:
                    return .none
                }

                guard let userLocation = state.userLocation else { return .none }
                state.cameraMoveRequest = userLocation
                return .none

            case .diagnosisButtonTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none

            case .diagnosisButtonCloseButtonTapped:
                state.isDiagnosisMatchesButtonExpanded = false
                return .none

            case .diagnosisButtonAutoCollapseDelayFinished:
                state.isDiagnosisButtonExpanded = false
                return .none

            case .locationSearchStarted:
                state.listingSource = .locationSearch
                state.activeDiagnosisID = nil
                state.appliedFilterSource = .manual
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                return .none

            case let .diagnosisResultRequested(diagnosisID):
                state.path = StackState<Path.State>()
                state.activeDiagnosisID = diagnosisID
                state.listingSource = .diagnosis
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isFilterPresented = false
                state.appliedFilterSource = .diagnosis
                state.isDiagnosisButtonExpanded = false
                state.isDiagnosisMatchesButtonExpanded = true
                state.lastSearchedViewport = state.currentViewport
                state.showsResearchButton = false
                state.markers = []
                state.listings = []
                state.isDiagnosisDetailLoading = true
                state.isRecommendationsLoading = true
                state.diagnosisErrorMessage = nil
                state.recommendationsErrorMessage = nil

                let diagnosisClient = diagnosisClient
                return .merge(
                    .cancel(id: "MapFeature.diagnosisButtonAutoCollapse"),
                    .run { send in
                        do {
                            let detail = try await diagnosisClient.fetchDetail(diagnosisID)
                            await send(.diagnosisDetailResponse(.success(detail)))
                        } catch {
                            await send(.diagnosisDetailResponse(.failure(error)))
                        }
                    }
                    .cancellable(id: "MapFeature.diagnosisDetail", cancelInFlight: true),
                    .run { send in
                        do {
                            let recommendations = try await diagnosisClient.fetchRecommendations(diagnosisID)
                            await send(.diagnosisRecommendationsResponse(.success(recommendations)))
                        } catch {
                            await send(.diagnosisRecommendationsResponse(.failure(error)))
                        }
                    }
                    .cancellable(id: "MapFeature.diagnosisRecommendations", cancelInFlight: true)
                )

            case let .diagnosisDetailResponse(.success(detail)):
                guard state.activeDiagnosisID == detail.diagnosisID else { return .none }
                debugLogDiagnosisDetail(detail)
                let filter = MapFilterState(diagnosisDetail: detail)
                state.appliedFilter = filter
                state.editingFilter = filter
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = nil
                return .none

            case let .diagnosisDetailResponse(.failure(error)):
                debugLogDiagnosisError("detail", error)
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = error.localizedDescription
                return .none

            case let .diagnosisRecommendationsResponse(.success(recommendations)):
                debugLogDiagnosisRecommendations(recommendations)
                state.listings = recommendations.listings.map(ListingItemModel.init(recommendation:))
                state.markers = recommendations.markers
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isRecommendationsLoading = false
                state.recommendationsErrorMessage = nil
                return .none

            case let .diagnosisRecommendationsResponse(.failure(error)):
                debugLogDiagnosisError("recommendations", error)
                state.isRecommendationsLoading = false
                state.recommendationsErrorMessage = error.localizedDescription
                return .none

            case .locationPermissionDialogCloseButtonTapped:
                state.isLocationPermissionDialogPresented = false
                return .none

            case .locationPermissionDialogSettingsButtonTapped:
                state.isLocationPermissionDialogPresented = false
                return .run { [settingsClient] _ in
                    await settingsClient.openApplicationSettings()
                }

            case .cameraMoveRequestHandled:
                state.cameraMoveRequest = nil
                return .none

            case let .markerTapped(id):
                guard state.selectedMarkerID != id else { return .none }
                state.selectedMarkerID = id
                state.sheetMode = .selectedListing
                return .none

            case .researchButtonTapped:
                state.lastSearchedViewport = state.currentViewport
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.showsResearchButton = false
                return .none

            case let .viewportChanged(viewport):
                state.currentViewport = viewport
                guard let lastSearchedViewport = state.lastSearchedViewport else {
                    state.lastSearchedViewport = viewport
                    state.showsResearchButton = false
                    return .none
                }

                state.showsResearchButton = lastSearchedViewport != viewport
                return .none

            case .path(.element(id: _, action: .listingDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .chatBot(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path:
                return .none

            case let .listingTapped(id):
                state.selectedMarkerID = id
                state.sheetMode = .selectedListing
                return .none

            case let .listingLikeButtonTapped(listingID):
                guard let index = state.listings.firstIndex(where: { $0.listingID == listingID }) else { return .none }
                state.listings[index].isLiked.toggle()
                return .none

            case .selectedListingCardTapped:
                guard let selectedMarkerID = state.selectedMarkerID else { return .none }
                state.path.append(.listingDetail(ListingDetailFeature.State(listingID: selectedMarkerID)))
                return .none

            case .selectedListingCloseButtonTapped:
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                return .none

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
                state.appliedFilter = state.editingFilter
                state.appliedFilterSource = .manual
                state.isDiagnosisMatchesButtonExpanded = true
                state.isFilterPresented = false
                return .none

            case .filterResetButtonTapped:
                state.editingFilter = MapFilterState()
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MapFeature.Path.State: Equatable {}
