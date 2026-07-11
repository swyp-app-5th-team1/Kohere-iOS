//
//  NaverMapRepresentable.swift
//  Kohere
//
//  Created by Codex on 6/23/26.
//

import NMapsMap
import SwiftUI

// MARK: - Naver Map Bridge

struct NaverMapRepresentable: UIViewRepresentable {
    let markers: [MapMarkerItem]
    let selectedMarkerID: String?
    let cameraMoveRequest: MapCoordinate?
    let onViewportChanged: (MapViewport) -> Void
    let onCameraMoveRequestHandled: () -> Void
    let onMarkerTapped: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onViewportChanged: onViewportChanged,
            onCameraMoveRequestHandled: onCameraMoveRequestHandled,
            onMarkerTapped: onMarkerTapped
        )
    }

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        mapView.addCameraDelegate(delegate: context.coordinator)
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: 37.5559, lng: 126.9250),
            zoomTo: 13
        )
        mapView.moveCamera(cameraUpdate)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        context.coordinator.updateMarkersIfNeeded(markers, on: uiView)
        context.coordinator.updateSelectedMarkerIfNeeded(selectedMarkerID)
        context.coordinator.moveCameraIfNeeded(to: cameraMoveRequest, on: uiView)
    }

    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        private let onViewportChanged: (MapViewport) -> Void
        private let onCameraMoveRequestHandled: () -> Void
        private let onMarkerTapped: (String) -> Void
        private var handledCameraMoveRequest: MapCoordinate?
        private var selectedMarkerID: String?
        private var clusterer: NMCClusterer<MapClusteringKey>?
        private var renderedItemsByID: [String: MapMarkerItem] = [:]
        private var clusteringKeysByID: [String: MapClusteringKey] = [:]
        private var leafMarkersByID: [String: NMFMarker] = [:]

        init(
            onViewportChanged: @escaping (MapViewport) -> Void,
            onCameraMoveRequestHandled: @escaping () -> Void,
            onMarkerTapped: @escaping (String) -> Void
        ) {
            self.onViewportChanged = onViewportChanged
            self.onCameraMoveRequestHandled = onCameraMoveRequestHandled
            self.onMarkerTapped = onMarkerTapped
            super.init()
        }

        // 지도 이동이 완전히 끝난 시점의 화면 정보를 TCA 상태로 전달한다.
        func mapViewCameraIdle(_ mapView: NMFMapView) {
            onViewportChanged(makeMapViewport(from: mapView))
        }

        // 마커 데이터 추가, 삭제, 좌표 변경이 있을 때만 클러스터러 데이터를 갱신한다.
        func updateMarkersIfNeeded(_ items: [MapMarkerItem], on mapView: NMFMapView) {
            let incomingItemsByID = items.reduce(into: [String: MapMarkerItem]()) { result, item in
                result[item.id] = item
            }

            guard renderedItemsByID != incomingItemsByID else { return }

            let incomingIDs = Set(incomingItemsByID.keys)
            let renderedIDs = Set(renderedItemsByID.keys)
            let removedIDs = renderedIDs.subtracting(incomingIDs)
            let changedIDs = incomingIDs.filter { id in
                renderedItemsByID[id] != incomingItemsByID[id]
            }
            removeRenderedMarkers(removedIDs, on: mapView)
            rerenderMarkers(Set(changedIDs), sourceItemsByID: incomingItemsByID, on: mapView)
        }

        // 선택 상태가 바뀐 이전/새 마커만 찾아 크기 전환을 적용한다.
        func updateSelectedMarkerIfNeeded(_ newSelectedMarkerID: String?) {
            guard selectedMarkerID != newSelectedMarkerID else { return }

            let oldSelectedMarkerID = selectedMarkerID
            selectedMarkerID = newSelectedMarkerID

            [
                oldSelectedMarkerID,
                newSelectedMarkerID
            ].compactMap { $0 }
                .forEach { id in
                    guard let marker = leafMarkersByID[id] else { return }

                    applyPropertyMarkerStyle(
                        to: marker,
                        isSelected: selectedMarkerID == id,
                        animated: true
                    )
                }
        }

        // 일회성 카메라 이동 요청을 받아 현재 줌 레벨을 유지한 채 지도 중심만 이동한다.
        func moveCameraIfNeeded(to coordinate: MapCoordinate?, on mapView: NMFMapView) {
            guard let coordinate else {
                handledCameraMoveRequest = nil
                return
            }

            guard handledCameraMoveRequest != coordinate else { return }
            handledCameraMoveRequest = coordinate

            let cameraUpdate = NMFCameraUpdate(
                scrollTo: makeNaverLatLng(from: coordinate),
                zoomTo: mapView.cameraPosition.zoom
            )
            mapView.moveCamera(cameraUpdate)
            DispatchQueue.main.async { [onCameraMoveRequestHandled] in
                onCameraMoveRequestHandled()
            }
        }

        // 클러스터러와 로컬 캐시에서 더 이상 유효하지 않은 마커를 제거한다.
        private func removeRenderedMarkers(_ ids: Set<String>, on mapView: NMFMapView) {
            let clusterer = configuredClusterer(on: mapView)
            let removedKeys = ids.compactMap { clusteringKeysByID[$0] }

            if !removedKeys.isEmpty {
                clusterer.removeAll(removedKeys)
            }

            ids.forEach { id in
                renderedItemsByID[id] = nil
                clusteringKeysByID[id] = nil
                leafMarkersByID[id] = nil
            }
        }

        // 변경된 마커 데이터를 클러스터러에 다시 등록해 SDK updater가 스타일을 재적용하게 한다.
        private func rerenderMarkers(
            _ ids: Set<String>,
            sourceItemsByID: [String: MapMarkerItem],
            on mapView: NMFMapView
        ) {
            guard !ids.isEmpty else { return }

            let clusterer = configuredClusterer(on: mapView)
            removeRenderedMarkers(ids, on: mapView)

            let keyTagMap = ids.reduce(into: [MapClusteringKey: NSObject]()) { result, id in
                guard let item = sourceItemsByID[id] else { return }
                let key = MapClusteringKey(item: item)
                result[key] = NSString(string: item.id)
                renderedItemsByID[id] = item
                clusteringKeysByID[id] = key
            }

            if !keyTagMap.isEmpty {
                clusterer.addAll(keyTagMap)
            }
        }

        // 클러스터러를 한 번만 생성하고 이후에는 같은 인스턴스를 재사용한다.
        private func configuredClusterer(on mapView: NMFMapView) -> NMCClusterer<MapClusteringKey> {
            if let clusterer {
                return clusterer
            }

            let builder = NMCBuilder<MapClusteringKey>()
            builder.clusterMarkerUpdater = MapClusterMarkerUpdater()
            builder.leafMarkerUpdater = MapLeafMarkerUpdater(
                isSelected: { [weak self] id in
                    self?.selectedMarkerID == id
                },
                onLeafMarkerUpdated: { [weak self] id, marker in
                    self?.leafMarkersByID[id] = marker
                },
                onMarkerTapped: onMarkerTapped
            )

            let clusterer = builder.build()
            clusterer.mapView = mapView
            self.clusterer = clusterer
            return clusterer
        }
    }
}

// MARK: - Cluster Marker

private final class MapClusterMarkerUpdater: NSObject, NMCClusterMarkerUpdater {
    private let defaultUpdater = NMCDefaultClusterMarkerUpdater()

    // 클러스터 개수에 맞춰 클러스터 마커 에셋, 크기, 캡션을 적용한다.
    func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        defaultUpdater.updateClusterMarker(info, marker)

        let isDoubleDigit = info.size >= 10
        let size = isDoubleDigit ? 48 : 36

        marker.iconImage = isDoubleDigit
            ? MapMarkerImageFactory.clusterMarkerDouble
            : MapMarkerImageFactory.clusterMarkerSingle
        marker.width = CGFloat(size)
        marker.height = CGFloat(size)
        marker.anchor = CGPoint(x: 0.5, y: 0.5)
        marker.captionText = "\(info.size)"
        marker.captionAligns = [NMFAlignType.center]
        marker.captionColor = .white
        marker.captionHaloColor = .clear
        marker.captionTextSize = 14
        marker.captionOffset = 0
    }
}

// MARK: - Clustering Key

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

// MARK: - Leaf Marker

private final class MapLeafMarkerUpdater: NSObject, NMCLeafMarkerUpdater {
    private let defaultUpdater = NMCDefaultLeafMarkerUpdater()
    private let isSelected: (String) -> Bool
    private let onLeafMarkerUpdated: (String, NMFMarker) -> Void
    private let onMarkerTapped: (String) -> Void

    init(
        isSelected: @escaping (String) -> Bool,
        onLeafMarkerUpdated: @escaping (String, NMFMarker) -> Void,
        onMarkerTapped: @escaping (String) -> Void
    ) {
        self.isSelected = isSelected
        self.onLeafMarkerUpdated = onLeafMarkerUpdated
        self.onMarkerTapped = onMarkerTapped
    }

    // 단일 매물 마커가 렌더링될 때 현재 선택 상태에 맞는 크기와 탭 핸들러를 적용한다.
    func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        defaultUpdater.updateLeafMarker(info, marker)

        guard let key = info.key as? MapClusteringKey else { return }
        onLeafMarkerUpdated(key.id, marker)

        applyPropertyMarkerStyle(
            to: marker,
            isSelected: isSelected(key.id),
            animated: false
        )
        marker.touchHandler = { [weak self] _ in
            self?.onMarkerTapped(key.id)
            return true
        }
    }
}
