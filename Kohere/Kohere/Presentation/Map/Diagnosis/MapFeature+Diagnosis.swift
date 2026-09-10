//
//  MapFeature+Diagnosis.swift
//  Kohere
//
//  Created by Codex on 7/15/26.
//

import ComposableArchitecture
import Foundation

extension MapFeature {
    func beginDiagnosisSearch(
        diagnosisID: Int,
        filter: MapFilterState,
        state: inout State
    ) -> Effect<Action> {
        state.path = StackState<Path.State>()
        state.activeDiagnosisID = diagnosisID
        state.listingSource = .diagnosis
        state.clearSelectedListing()
        state.isFilterPresented = false
        state.appliedFilterSource = .diagnosis
        state.appliedFilter = filter
        state.editingFilter = filter
        state.pendingViewportSearchTarget = nil
        state.selectedPlaceSearchTitle = nil
        state.isDiagnosisButtonExpanded = false
        state.isDiagnosisMatchesButtonExpanded = true
        state.showsResearchButton = false
        state.lastSearchedViewport = nil
        state.markers = []
        state.listings = []
        state.listingSearchResults = []
        clearDiagnosisRecommendationState(state: &state)
        state.isListingSearchLoading = false
        state.isDiagnosisDetailLoading = state.userType != nil
        state.isRecommendationsLoading = true
        state.listingSearchErrorMessage = nil
        state.diagnosisErrorMessage = nil
        state.recommendationsErrorMessage = nil

        let diagnosisClient = diagnosisClient
        var effects: [Effect<Action>] = [
            .cancel(id: MapEffectID.diagnosisButtonAutoCollapse),
            .cancel(id: MapEffectID.diagnosisDetail),
            .cancel(id: MapEffectID.diagnosisRecommendations),
            .cancel(id: MapEffectID.listingSearch),
            .cancel(id: MapEffectID.listingMapMarkers),
            .run { send in
                do {
                    let input = DiagnosisRecommendationsInput(diagnosisID: diagnosisID)
                    let recommendations = try await diagnosisClient.fetchRecommendations(input)
                    try Task.checkCancellation()
                    await send(.diagnosisRecommendationsResponse(.success(recommendations), isFirstPage: true))
                } catch {
                    guard !isDiagnosisRequestCancellation(error) else { return }
                    await send(.diagnosisRecommendationsResponse(.failure(error), isFirstPage: true))
                }
            }
            .cancellable(id: MapEffectID.diagnosisRecommendations, cancelInFlight: true),
            startDiagnosisMapEffect(diagnosisID: diagnosisID, state: &state)
        ]

        if state.userType != nil {
            effects.append(.run { send in
                do {
                    let detail = try await diagnosisClient.fetchDetail(diagnosisID)
                    try Task.checkCancellation()
                    await send(.diagnosisDetailResponse(.success(detail)))
                } catch {
                    guard !isDiagnosisRequestCancellation(error) else { return }
                    await send(.diagnosisDetailResponse(.failure(error)))
                }
            }
            .cancellable(id: MapEffectID.diagnosisDetail, cancelInFlight: true))
        }

        return .merge(effects)
    }

    func handleDiagnosisDetailResponse(
        _ result: Result<DiagnosisDetail, Error>,
        state: inout State
    ) -> Effect<Action> {
        switch result {
        case let .success(detail):
            guard state.activeDiagnosisID == detail.diagnosisID else { return .none }
            let filter = MapFilterState(diagnosisDetail: detail)
            let shouldReloadSelectedCard = state.appliedFilter != filter
                && (state.selectedListing != nil || state.selectedListingRequestID != nil)
            let selectedID = state.selectedMarkerID
            state.appliedFilter = filter
            state.editingFilter = filter
            state.isDiagnosisDetailLoading = false
            state.diagnosisErrorMessage = nil

            // 진단 상세가 늦게 와 조건을 보정했다면, 이전 조건으로 조회하던 카드도 갱신한다.
            if shouldReloadSelectedCard, let selectedID {
                state.clearSelectedListing()
                return selectMarker(selectedID, state: &state)
            }

        case let .failure(error):
            guard state.listingSource == .diagnosis else { return .none }
            state.isDiagnosisDetailLoading = false
            state.diagnosisErrorMessage = error.localizedDescription
        }

        return .none
    }

    func handleDiagnosisRecommendationsResponse(
        _ result: Result<DiagnosisRecommendations, Error>,
        isFirstPage: Bool,
        state: inout State
    ) -> Effect<Action> {
        guard state.listingSource == .diagnosis else { return .none }

        switch result {
        case let .success(recommendations):
            applyDiagnosisRecommendations(recommendations, isFirstPage: isFirstPage, to: &state)
            state.isRecommendationsLoading = false
            state.recommendationsErrorMessage = nil

        case let .failure(error):
            state.isRecommendationsLoading = false
            state.recommendationsErrorMessage = error.localizedDescription
            state.diagnosisRecommendationSuggestions = nil
        }

        return .none
    }

    func startNextDiagnosisRecommendationPageEffect(
        appearedListingID: String,
        state: inout State
    ) -> Effect<Action> {
        guard state.listings.last?.listingID == appearedListingID,
              !state.isRecommendationsLoading,
              state.listingSource == .diagnosis,
              state.diagnosisRecommendationPageInfo?.hasNext == true,
              let diagnosisID = state.activeDiagnosisID
        else { return .none }

        let nextPage = (state.diagnosisRecommendationPageInfo?.number ?? 0) + 1
        let pageSize = state.diagnosisRecommendationPageInfo?.size
            ?? DiagnosisRecommendationsInput.defaultPageSize
        state.isRecommendationsLoading = true
        state.recommendationsErrorMessage = nil

        let input = DiagnosisRecommendationsInput(
            diagnosisID: diagnosisID,
            page: nextPage,
            size: pageSize
        )

        return .run { [diagnosisClient] send in
            do {
                let recommendations = try await diagnosisClient.fetchRecommendations(input)
                try Task.checkCancellation()
                await send(.diagnosisRecommendationsResponse(.success(recommendations), isFirstPage: false))
            } catch {
                guard !isDiagnosisRequestCancellation(error) else { return }
                await send(.diagnosisRecommendationsResponse(.failure(error), isFirstPage: false))
            }
        }
        .cancellable(id: MapEffectID.diagnosisRecommendations, cancelInFlight: true)
    }

    func applyDiagnosisRecommendations(
        _ recommendations: DiagnosisRecommendations,
        isFirstPage: Bool,
        to state: inout State
    ) {
        state.diagnosisRecommendationPageInfo = recommendations.page

        if isFirstPage {
            state.diagnosisRecommendedListings = recommendations.listings
            state.diagnosisRecommendationSuggestions = recommendations.suggestions

            let cameraCoordinate = recommendations.listings.compactMap(\.coordinate).first
            if state.selectedMarkerID == nil {
                state.cameraMoveRequest = cameraCoordinate.map {
                    MapCameraMoveRequest(coordinate: $0, targetPosition: .center)
                }
            }
            if cameraCoordinate == nil {
                state.lastSearchedViewport = state.currentViewport
            }
        } else {
            state.diagnosisRecommendedListings.appendUnique(contentsOf: recommendations.listings)
        }

        rebuildListingItems(to: &state)
    }

    func startDiagnosisMapEffect(diagnosisID: Int, state: inout State) -> Effect<Action> {
        let requestID = uuid()
        state.diagnosisMapRequestID = requestID
        state.diagnosisMapErrorMessage = nil
        return .run { [diagnosisClient] send in
            do {
                let map = try await diagnosisClient.fetchRecommendationMap(diagnosisID)
                try Task.checkCancellation()
                await send(.diagnosisMapResponse(requestID: requestID, .success(map)))
            } catch {
                guard !isDiagnosisRequestCancellation(error) else { return }
                await send(.diagnosisMapResponse(requestID: requestID, .failure(.from(error))))
            }
        }
        .cancellable(id: MapEffectID.diagnosisMap, cancelInFlight: true)
    }

    func handleDiagnosisMapResponse(
        requestID: UUID,
        result: Result<DiagnosisRecommendationMap, DataError>,
        state: inout State
    ) -> Effect<Action> {
        guard state.listingSource == .diagnosis,
              state.diagnosisMapRequestID == requestID else { return .none }
        state.diagnosisMapRequestID = nil

        switch result {
        case let .success(map):
            state.markers = map.markers.map { MapMarkerItem(id: $0.listingID, coordinate: $0.coordinate) }
            state.diagnosisMapTotal = map.total
            state.diagnosisMapErrorMessage = nil
        case let .failure(error):
            state.diagnosisMapErrorMessage = error.localizedDescription
        }
        return .none
    }

    func clearDiagnosisRecommendationState(state: inout State) {
        state.isRecommendationsLoading = false
        state.recommendationsErrorMessage = nil
        state.diagnosisRecommendedListings = []
        state.diagnosisRecommendationSuggestions = nil
        state.diagnosisRecommendationPageInfo = nil
        state.diagnosisMapRequestID = nil
        state.diagnosisMapTotal = nil
        state.diagnosisMapErrorMessage = nil
    }

    func cancelDiagnosisRequestEffects() -> Effect<Action> {
        .merge(
            .cancel(id: MapEffectID.diagnosisDetail),
            .cancel(id: MapEffectID.diagnosisRecommendations),
            .cancel(id: MapEffectID.diagnosisMap)
        )
    }

}

nonisolated private func isDiagnosisRequestCancellation(_ error: Error) -> Bool {
    Task.isCancelled
        || error is CancellationError
        || (error as? URLError)?.code == .cancelled
}
