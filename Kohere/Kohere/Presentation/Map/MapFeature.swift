//
//  MapFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

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
    }

    enum Action {
        case markerTapped(String)
        case researchButtonTapped
        case viewportChanged(MapViewport)
        case path(StackActionOf<Path>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .markerTapped(id):
                guard state.selectedMarkerID != id else { return .none }
                state.selectedMarkerID = id
                return .none

            case .researchButtonTapped:
                state.lastSearchedViewport = state.currentViewport
                state.showsResearchButton = false
                return .none

            case let .viewportChanged(viewport):
                state.currentViewport = viewport
                state.showsResearchButton = state.lastSearchedViewport != viewport
                return .none

            case .path:
                return .none
            }
        }
    }
}

extension MapFeature.Path.State: Equatable {}
