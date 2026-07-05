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

    @Reducer
    enum Path {
        case listingDetail(ListingDetailFeature)
        case chatBot(ChatBotFeature)
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
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isDiagnosisDetailLoading = false
                state.isRecommendationsLoading = false
                state.diagnosisErrorMessage = nil
                state.recommendationsErrorMessage = nil

                guard let viewport = state.currentViewport,
                      canStartListingSearch(state: state)
                else { return .none }

                return startListingSearchEffect(state: &state, viewport: viewport)

            case let .diagnosisResultRequested(diagnosisID):
                state.path = StackState<Path.State>()
                state.activeDiagnosisID = nil
                state.listingSource = .locationSearch
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.isFilterPresented = false
                state.appliedFilterSource = .manual
                state.isDiagnosisButtonExpanded = false
                state.isDiagnosisMatchesButtonExpanded = false
                state.showsResearchButton = false
                state.isDiagnosisDetailLoading = false
                state.isRecommendationsLoading = false
                state.diagnosisErrorMessage = nil
                state.recommendationsErrorMessage = nil

                var effects: [Effect<Action>] = [
                    .cancel(id: "MapFeature.diagnosisButtonAutoCollapse"),
                    .cancel(id: "MapFeature.diagnosisDetail"),
                    .cancel(id: "MapFeature.diagnosisRecommendations")
                ]

                if let viewport = state.currentViewport,
                   canStartListingSearch(state: state) {
                    effects.append(startListingSearchEffect(state: &state, viewport: viewport))
                }

                debugLogDiagnosisGeneralListingFallback(diagnosisID: diagnosisID)
                return .merge(effects)

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
                guard let viewport = state.currentViewport else { return .none }
                state.listingSource = .locationSearch
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                return startListingSearchEffect(state: &state, viewport: viewport)

            case let .viewportChanged(viewport):
                state.currentViewport = viewport

                guard state.listingSource == .locationSearch else {
                    state.showsResearchButton = false
                    return .none
                }

                guard let lastSearchedViewport = state.lastSearchedViewport else {
                    state.showsResearchButton = false
                    guard canStartFirstListingSearch(state: state) else { return .none }
                    return startListingSearchEffect(state: &state, viewport: viewport)
                }

                guard lastSearchedViewport != viewport else {
                    state.showsResearchButton = false
                    return .none
                }

                state.showsResearchButton = true
                return .none

            case let .listingSearchResponse(.success(page)):
                debugLogListingSearchResponse(page)
                state.isListingSearchLoading = false
                state.listingSearchErrorMessage = nil
                state.listingPageInfo = page.page
                state.listings = page.content.map(ListingItemModel.init(listing:))
                state.markers = page.content.compactMap { listing in
                    guard let coordinate = listing.coordinate else { return nil }
                    return MapMarkerItem(id: listing.id, coordinate: coordinate)
                }
                if let selectedMarkerID = state.selectedMarkerID,
                   !state.markers.contains(where: { $0.id == selectedMarkerID }) {
                    state.selectedMarkerID = nil
                }
                return .none

            case let .listingSearchResponse(.failure(error)):
                debugLogListingSearchError(error)
                state.isListingSearchLoading = false
                state.listingSearchErrorMessage = error.localizedDescription
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
                if state.appliedFilterSource != .diagnosis {
                    state.appliedFilterSource = .manual
                }
                state.isDiagnosisMatchesButtonExpanded = true
                state.isFilterPresented = false
                state.listingSource = .locationSearch

                guard let viewport = state.currentViewport,
                      canStartListingSearch(state: state)
                else { return .none }

                return startListingSearchEffect(state: &state, viewport: viewport)

            case .filterResetButtonTapped:
                state.editingFilter = MapFilterState()
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MapFeature.Path.State: Equatable {}
