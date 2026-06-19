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
        private var clusterer: NMCClusterer<MapClusteringKey>?
        private var renderedItemsByID: [String: MapMarkerItem] = [:]
        private var clusteringKeysByID: [String: MapClusteringKey] = [:]

        init(onMarkerTapped: @escaping (String) -> Void) {
            self.onMarkerTapped = onMarkerTapped
        }

        func updateMarkers(_ items: [MapMarkerItem], on mapView: NMFMapView) {
            let clusterer = configuredClusterer(on: mapView)
            let incomingItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            let incomingIDs = Set(incomingItemsByID.keys)
            let renderedIDs = Set(renderedItemsByID.keys)
            let removedIDs = renderedIDs.subtracting(incomingIDs)
            let changedIDs = incomingIDs.filter { id in
                renderedItemsByID[id] != incomingItemsByID[id]
            }
            let removedOrChangedIDs = removedIDs.union(changedIDs)
            let removedKeys = removedOrChangedIDs.compactMap { clusteringKeysByID[$0] }

            if !removedKeys.isEmpty {
                clusterer.removeAll(removedKeys)
            }

            removedOrChangedIDs.forEach { id in
                renderedItemsByID[id] = nil
                clusteringKeysByID[id] = nil
            }

            let keyTagMap = changedIDs.reduce(into: [MapClusteringKey: NSObject]()) { result, id in
                guard let item = incomingItemsByID[id] else { return }
                let key = MapClusteringKey(item: item)
                result[key] = NSString(string: item.id)
                renderedItemsByID[id] = item
                clusteringKeysByID[id] = key
            }

            if !keyTagMap.isEmpty {
                clusterer.addAll(keyTagMap)
            }
        }

        private func configuredClusterer(on mapView: NMFMapView) -> NMCClusterer<MapClusteringKey> {
            if let clusterer {
                return clusterer
            }

            let builder = NMCBuilder<MapClusteringKey>()
            builder.leafMarkerUpdater = MapLeafMarkerUpdater(onMarkerTapped: onMarkerTapped)

            let clusterer = builder.build()
            clusterer.mapView = mapView
            self.clusterer = clusterer
            return clusterer
        }
    }
}

private final class MapClusteringKey: NSObject, NMCClusteringKey {
    let id: String
    let position: NMGLatLng

    init(item: MapMarkerItem) {
        id = item.id
        position = makeNaverLatLng(from: item.coordinate)
    }

    func copy(with zone: NSZone? = nil) -> Any {
        self
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MapClusteringKey else { return false }
        return id == other.id
    }

    override var hash: Int {
        id.hashValue
    }
}

private final class MapLeafMarkerUpdater: NSObject, NMCLeafMarkerUpdater {
    private let defaultUpdater = NMCDefaultLeafMarkerUpdater()
    private let onMarkerTapped: (String) -> Void

    init(onMarkerTapped: @escaping (String) -> Void) {
        self.onMarkerTapped = onMarkerTapped
    }

    func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        defaultUpdater.updateLeafMarker(info, marker)

        guard let key = info.key as? MapClusteringKey else { return }
        marker.touchHandler = { [weak self] _ in
            self?.onMarkerTapped(key.id)
            return true
        }
    }
}

private func makeNaverLatLng(from coordinate: MapCoordinate) -> NMGLatLng {
    NMGLatLng(
        lat: coordinate.latitude,
        lng: coordinate.longitude
    )
}
