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
        NaverMapRepresentable()
            .ignoresSafeArea(edges: .top)
    }
}

private struct NaverMapRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: 37.5666102, lng: 126.9783881),
            zoomTo: 13
        )
        mapView.moveCamera(cameraUpdate)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {}
}
