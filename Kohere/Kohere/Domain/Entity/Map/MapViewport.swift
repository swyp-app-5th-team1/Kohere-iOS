//
//  MapViewport.swift
//  Kohere
//
//  Created by Codex on 6/22/26.
//

struct MapViewport: Equatable {
    let center: MapCoordinate
    let zoomLevel: Double
    let visibleBounds: MapBounds
}

struct MapBounds: Equatable {
    let southWest: MapCoordinate
    let northEast: MapCoordinate
}
