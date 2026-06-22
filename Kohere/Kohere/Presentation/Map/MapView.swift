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
        ZStack(alignment: .top) {
            NaverMapRepresentable(
                markers: store.markers,
                selectedMarkerID: store.selectedMarkerID,
                onViewportChanged: { viewport in
                    store.send(.viewportChanged(viewport))
                },
                onMarkerTapped: { id in
                    store.send(.markerTapped(id))
                }
            )
            .ignoresSafeArea()

            if store.showsResearchButton {
                researchButton
                    .padding(.top, 12)
            }
        }
    }

    private var researchButton: some View {
        Button {
            store.send(.researchButtonTapped)
        } label: {
            HStack(spacing: 12) {
                Image("refresh_16")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.blue100)

                Text("이 지역 검색하기")
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.blue100)
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .kohereSurface(
                background: .common0,
                shape: .capsule,
                elevation: .normalXSmall
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Naver Map Bridge

private struct NaverMapRepresentable: UIViewRepresentable {
    let markers: [MapMarkerItem]
    let selectedMarkerID: String?
    let onViewportChanged: (MapViewport) -> Void
    let onMarkerTapped: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onViewportChanged: onViewportChanged,
            onMarkerTapped: onMarkerTapped
        )
    }

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: 37.5559, lng: 126.9250),
            zoomTo: 13
        )
        mapView.moveCamera(cameraUpdate)
        mapView.addCameraDelegate(delegate: context.coordinator)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        context.coordinator.updateMarkersIfNeeded(markers, on: uiView)
        context.coordinator.updateSelectedMarkerIfNeeded(selectedMarkerID)
    }

    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        private let onViewportChanged: (MapViewport) -> Void
        private let onMarkerTapped: (String) -> Void
        private var selectedMarkerID: String?
        private var clusterer: NMCClusterer<MapClusteringKey>?
        private var renderedItemsByID: [String: MapMarkerItem] = [:]
        private var clusteringKeysByID: [String: MapClusteringKey] = [:]
        private var leafMarkersByID: [String: NMFMarker] = [:]

        init(
            onViewportChanged: @escaping (MapViewport) -> Void,
            onMarkerTapped: @escaping (String) -> Void
        ) {
            self.onViewportChanged = onViewportChanged
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

// MARK: - Marker Images

private enum MapMarkerImageFactory {
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
private func applyPropertyMarkerStyle(
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

private func makeNaverLatLng(from coordinate: MapCoordinate) -> NMGLatLng {
    NMGLatLng(
        lat: coordinate.latitude,
        lng: coordinate.longitude
    )
}

private func makeMapViewport(from mapView: NMFMapView) -> MapViewport {
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

private func makeMapCoordinate(from latLng: NMGLatLng) -> MapCoordinate {
    MapCoordinate(
        latitude: latLng.lat,
        longitude: latLng.lng
    )
}
