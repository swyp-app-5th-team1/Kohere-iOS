//
//  ListingDetailMapPreview.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import NMapsMap
import SwiftUI

struct ListingDetailMapPreview: View {
    let coordinate: MapCoordinate?
    let onTap: () -> Void

    var body: some View {
        ZStack {
            if let coordinate {
                ListingDetailNaverMapPreview(coordinate: coordinate)
                    .allowsHitTesting(false)
            } else {
                ListingDetailMapPlaceholder()
            }

            if coordinate != nil {
                Button(action: onTap) {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("지도에서 위치 보기")
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ListingDetailNaverMapPreview: UIViewRepresentable {
    let coordinate: MapCoordinate

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        updateCamera(on: mapView)
        updateMarker(on: mapView, coordinator: context.coordinator)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        updateCamera(on: uiView)
        updateMarker(on: uiView, coordinator: context.coordinator)
    }

    private func updateCamera(on mapView: NMFMapView) {
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: makeNaverLatLng(from: coordinate),
            zoomTo: 15
        )
        mapView.moveCamera(cameraUpdate)
    }

    private func updateMarker(on mapView: NMFMapView, coordinator: Coordinator) {
        let marker = coordinator.marker ?? NMFMarker()
        marker.position = makeNaverLatLng(from: coordinate)
        applyPropertyMarkerStyle(
            to: marker,
            isSelected: true,
            animated: false
        )
        marker.anchor = CGPoint(x: 0.5, y: 0.5)
        marker.mapView = mapView
        coordinator.marker = marker
    }

    final class Coordinator {
        var marker: NMFMarker?
    }
}

private struct ListingDetailMapPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.neutral5)
            .overlay {
                ZStack {
                    VStack(spacing: 18) {
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                    }
                    .rotationEffect(.degrees(-12))

                    VStack(spacing: 24) {
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                    }

                    Image("MapPropertyMarker")
                        .resizable()
                        .frame(width: 44, height: 44)
                }
                .padding(18)
            }
    }
}
