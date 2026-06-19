//
//  MapView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import NMapsMap
import SwiftUI

struct MapView: View {
    let store: StoreOf<MapFeature>

    var body: some View {
        NaverMapRepresentable(
            markers: store.markers,
            onMarkerTapped: { id in
                store.send(.markerTapped(id))
            }
        )
            .ignoresSafeArea(edges: .top)
    }
}

private struct NaverMapRepresentable: UIViewRepresentable {
    let markers: [MapMarkerItem]
    let onMarkerTapped: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMarkerTapped: onMarkerTapped)
    }

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: 37.5559, lng: 126.9250),
            zoomTo: 13
        )
        mapView.moveCamera(cameraUpdate)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        context.coordinator.updateMarkers(markers, on: uiView)
    }

    final class Coordinator {
        private let onMarkerTapped: (String) -> Void
        private var renderedMarkers: [String: NMFMarker] = [:]

        init(onMarkerTapped: @escaping (String) -> Void) {
            self.onMarkerTapped = onMarkerTapped
        }

        func updateMarkers(_ items: [MapMarkerItem], on mapView: NMFMapView) {
            let itemIDs = Set(items.map(\.id))
            let removedIDs = Set(renderedMarkers.keys).subtracting(itemIDs)

            removedIDs.forEach { id in
                renderedMarkers[id]?.mapView = nil
                renderedMarkers[id] = nil
            }

            items.forEach { item in
                let position = makeNaverLatLng(from: item.coordinate)

                if let marker = renderedMarkers[item.id] {
                    marker.position = position
                } else {
                    let marker = NMFMarker(position: position)
                    marker.touchHandler = { [weak self] _ in
                        self?.onMarkerTapped(item.id)
                        return true
                    }
                    marker.mapView = mapView
                    renderedMarkers[item.id] = marker
                }
            }
        }
    }
}

private func makeNaverLatLng(from coordinate: MapCoordinate) -> NMGLatLng {
    NMGLatLng(
        lat: coordinate.latitude,
        lng: coordinate.longitude
    )
}
