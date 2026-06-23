//
//  MapFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

enum MapLocationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@Reducer
struct MapFeature {
    @Reducer
    enum Path {
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var markers: [MapMarkerItem] = [
            MapMarkerItem(
                id: "hongdae-station",
                coordinate: MapCoordinate(latitude: 37.557192, longitude: 126.925381)
            ),
            MapMarkerItem(
                id: "sinchon-station",
                coordinate: MapCoordinate(latitude: 37.555134, longitude: 126.936893)
            ),
            MapMarkerItem(
                id: "hapjeong-station",
                coordinate: MapCoordinate(latitude: 37.549463, longitude: 126.913739)
            )
        ]
        var selectedMarkerID: String?
        var currentViewport: MapViewport?
        var lastSearchedViewport: MapViewport?
        var showsResearchButton = false
        var locationAuthorization: MapLocationAuthorization = .notDetermined
        var userLocation: MapCoordinate?
        var cameraMoveRequest: MapCoordinate?
        var hasMovedToInitialUserLocation = false
    }

    enum Action {
        case locationAuthorizationChanged(MapLocationAuthorization)
        case userLocationUpdated(MapCoordinate)
        case myLocationButtonTapped
        case cameraMoveRequestHandled
        case markerTapped(String)
        case researchButtonTapped
        case viewportChanged(MapViewport)
        case path(StackActionOf<Path>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
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
                guard state.locationAuthorization == .authorized else { return .none }
                guard let userLocation = state.userLocation else { return .none }
                state.cameraMoveRequest = userLocation
                return .none

            case .cameraMoveRequestHandled:
                state.cameraMoveRequest = nil
                return .none

            case let .markerTapped(id):
                guard state.selectedMarkerID != id else { return .none }
                state.selectedMarkerID = id
                return .none

            case .researchButtonTapped:
                state.lastSearchedViewport = state.currentViewport
                state.selectedMarkerID = nil
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

            case .path:
                return .none
            }
        }
    }
}

extension MapFeature.Path.State: Equatable {}
