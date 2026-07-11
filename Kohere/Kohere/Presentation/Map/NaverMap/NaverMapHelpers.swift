//
//  NaverMapHelpers.swift
//  Kohere
//
//  Created by Codex on 6/23/26.
//

import NMapsMap

// MARK: - Marker Images

enum MapMarkerImageFactory {
    static let propertyMarker = NMFOverlayImage(
        name: "MapPropertyMarker",
        reuseIdentifier: "MapPropertyMarker"
    )
    static let clusterMarkerSingle = NMFOverlayImage(
        name: "MapClusterMarkerSingle",
        reuseIdentifier: "MapClusterMarkerSingle"
    )
    static let clusterMarkerDouble = NMFOverlayImage(
        name: "MapClusterMarkerDouble",
        reuseIdentifier: "MapClusterMarkerDouble"
    )
}

// MARK: - Marker Styling

// 단일 매물 마커는 같은 에셋을 유지하고 선택 상태에 따라 크기만 바꾼다.
func applyPropertyMarkerStyle(
    to marker: NMFMarker,
    isSelected: Bool,
    animated: Bool
) {
    let targetSize: CGFloat = isSelected ? 44 : 36
    marker.iconImage = MapMarkerImageFactory.propertyMarker

    guard animated else {
        marker.width = targetSize
        marker.height = targetSize
        return
    }

    animatePropertyMarkerSize(marker, to: targetSize)
}

// NMFMarker 크기 속성을 짧은 단계로 보간해 선택 전환을 부드럽게 만든다.
private func animatePropertyMarkerSize(_ marker: NMFMarker, to targetSize: CGFloat) {
    let startSize = marker.width
    let steps = 6
    let duration: TimeInterval = 0.12
    let interval = duration / Double(steps)

    for step in 1...steps {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
            let progress = CGFloat(step) / CGFloat(steps)
            let size = startSize + (targetSize - startSize) * progress
            marker.width = size
            marker.height = size
        }
    }
}

// MARK: - Coordinate Mapping

func makeNaverLatLng(from coordinate: MapCoordinate) -> NMGLatLng {
    NMGLatLng(
        lat: coordinate.latitude,
        lng: coordinate.longitude
    )
}

func makeMapViewport(from mapView: NMFMapView) -> MapViewport {
    let cameraPosition = mapView.cameraPosition
    let contentBounds = mapView.contentBounds

    return MapViewport(
        center: makeMapCoordinate(from: cameraPosition.target),
        zoomLevel: cameraPosition.zoom,
        visibleBounds: MapBounds(
            southWest: makeMapCoordinate(from: contentBounds.southWest),
            northEast: makeMapCoordinate(from: contentBounds.northEast)
        )
    )
}

func makeMapCoordinate(from latLng: NMGLatLng) -> MapCoordinate {
    MapCoordinate(
        latitude: latLng.lat,
        longitude: latLng.lng
    )
}
