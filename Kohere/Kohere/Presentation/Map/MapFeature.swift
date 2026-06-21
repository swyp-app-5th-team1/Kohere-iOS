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
    }

    enum Action {
        case markerTapped(String)
        case path(StackActionOf<Path>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .markerTapped(id):
                state.selectedMarkerID = id
                return .none

            case .path:
                return .none
            }
        }
    }
}

extension MapFeature.Path.State: Equatable {}
