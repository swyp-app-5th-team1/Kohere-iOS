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
        case chatBot(ChatBotFeature)
        case search(SearchFeature)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .mapAppeared:
                var effects: [Effect<Action>] = [
                    startExchangeRateFetchEffect(),
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

                if state.listingSource == .idle {
                    effects.append(.send(.locationSearchStarted))
                }

                return .merge(effects)

            case .mapDismissed:
                state.isDiagnosisButtonExpanded = false
                return .merge(
                    .cancel(id: "MapFeature.locationUpdates"),
                    .cancel(id: "MapFeature.exchangeRate"),
                    .cancel(id: "MapFeature.diagnosisButtonAutoCollapse"),
                    .cancel(id: "MapFeature.diagnosisDetail"),
                    .cancel(id: "MapFeature.diagnosisRecommendations"),
                    .cancel(id: "MapFeature.listingSearch")
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

                guard authorization != .notDetermined,
                      state.listingSource == .locationSearch,
                      state.lastSearchedViewport == nil,
                      let viewport = state.currentViewport,
                      canStartFirstListingSearch(state: state)
                else { return .none }

                return startListingSearchEffect(state: &state, viewport: viewport)

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
                state.placeSearchTarget = nil
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = nil
                clearDiagnosisRecommendationState(state: &state)
                let cancelDiagnosisRequests = cancelDiagnosisRequestEffects()
                guard let viewport = state.currentViewport,
                      canStartListingSearch(state: state)
                else { return cancelDiagnosisRequests }

                return .merge(
                    cancelDiagnosisRequests,
                    startListingSearchEffect(state: &state, viewport: viewport)
                )

            case let .diagnosisResultRequested(diagnosisID):
                state.path = StackState<Path.State>()
                state.activeDiagnosisID = diagnosisID
                state.listingSource = .diagnosis
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isFilterPresented = false
                state.appliedFilterSource = .diagnosis
                state.placeSearchTarget = nil
                state.isDiagnosisButtonExpanded = false
                state.isDiagnosisMatchesButtonExpanded = true
                state.showsResearchButton = false
                state.lastSearchedViewport = nil
                state.markers = []
                state.listings = []
                state.listingSearchResults = []
                clearDiagnosisRecommendationState(state: &state)
                state.isListingSearchLoading = false
                state.isDiagnosisDetailLoading = true
                state.isRecommendationsLoading = true
                state.listingSearchErrorMessage = nil
                state.diagnosisErrorMessage = nil
                state.recommendationsErrorMessage = nil

                let diagnosisClient = diagnosisClient
                return .merge(
                    .cancel(id: "MapFeature.diagnosisButtonAutoCollapse"),
                    .cancel(id: "MapFeature.diagnosisDetail"),
                    .cancel(id: "MapFeature.diagnosisRecommendations"),
                    .cancel(id: "MapFeature.listingSearch"),
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
                            let input = DiagnosisRecommendationsInput(diagnosisID: diagnosisID)
                            let recommendations = try await diagnosisClient.fetchRecommendations(input)
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
                guard state.listingSource == .diagnosis else { return .none }
                debugLogDiagnosisError("detail", error)
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = error.localizedDescription
                return .none

            case let .exchangeRateResponse(.success(exchangeRate)):
                applyExchangeRate(exchangeRate, to: &state)
                return .none

            case .exchangeRateResponse(.failure):
                return .none

            case let .diagnosisRecommendationsResponse(.success(recommendations)):
                guard state.listingSource == .diagnosis else { return .none }
                debugLogDiagnosisRecommendations(recommendations)
                applyDiagnosisRecommendations(recommendations, to: &state)
                state.isRecommendationsLoading = false
                state.recommendationsErrorMessage = nil
                return .none

            case let .diagnosisRecommendationsResponse(.failure(error)):
                guard state.listingSource == .diagnosis else { return .none }
                debugLogDiagnosisError("recommendations", error)
                state.isRecommendationsLoading = false
                state.recommendationsErrorMessage = error.localizedDescription
                state.diagnosisRecommendationSuggestions = nil
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

            case .searchButtonTapped:
                state.path.append(.search(SearchFeature.initialState(userDefaultsClient: userDefaultsClient)))
                return .none
            case let .placeSearchResultSelected(placeResult):
                return handlePlaceSearchResultSelected(placeResult, state: &state)
            case .researchButtonTapped:
                guard let viewport = state.currentViewport else { return .none }
                state.listingSource = .locationSearch
                state.activeDiagnosisID = nil
                state.placeSearchTarget = nil
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = nil
                clearDiagnosisRecommendationState(state: &state)
                return .merge(
                    cancelDiagnosisRequestEffects(),
                    startListingSearchEffect(state: &state, viewport: viewport)
                )

            case let .viewportChanged(viewport):
                return handleViewportChanged(viewport, state: &state)

            case let .listingRowAppeared(listingID):
                return startNextPageEffect(appearedListingID: listingID, state: &state)

            case let .listingSearchResponse(.success(page)):
                guard state.listingSource == .locationSearch else { return .none }
                debugLogListingSearchResponse(page)
                state.isListingSearchLoading = false
                state.listingSearchErrorMessage = nil
                applyListingSearchPage(page, to: &state)
                return .none

            case let .listingSearchResponse(.failure(error)):
                guard state.listingSource == .locationSearch else { return .none }
                debugLogListingSearchError(error)
                state.isListingSearchLoading = false
                state.listingSearchErrorMessage = error.localizedDescription
                return .none

            case let .path(pathAction):
                return handlePathAction(pathAction, state: &state)

            case let .listingTapped(id):
                state.selectedMarkerID = id
                state.cameraMoveRequest = state.markers.first { $0.id == id }?.coordinate
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
                let previousAppliedFilter = state.appliedFilter
                state.appliedFilter = state.editingFilter
                if state.appliedFilterSource != .diagnosis || state.appliedFilter != previousAppliedFilter {
                    state.appliedFilterSource = .manual
                }
                state.isDiagnosisMatchesButtonExpanded = true
                state.isFilterPresented = false
                state.listingSource = .locationSearch
                state.activeDiagnosisID = nil
                state.placeSearchTarget = nil
                state.isDiagnosisDetailLoading = false
                state.diagnosisErrorMessage = nil
                clearDiagnosisRecommendationState(state: &state)
                let cancelDiagnosisRequests = cancelDiagnosisRequestEffects()
                guard let viewport = state.currentViewport,
                      canStartListingSearch(state: state)
                else { return cancelDiagnosisRequests }
                return .merge(
                    cancelDiagnosisRequests,
                    startListingSearchEffect(state: &state, viewport: viewport)
                )
            case .filterResetButtonTapped:
                state.editingFilter = MapFilterState()
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MapFeature.Path.State: Equatable {}
