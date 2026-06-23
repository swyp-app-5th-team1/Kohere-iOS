//
//  MapView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MapView: View {
    let store: StoreOf<MapFeature>

    var body: some View {
        ZStack(alignment: .top) {
            NaverMapRepresentable(
                markers: store.markers,
                selectedMarkerID: store.selectedMarkerID,
                cameraMoveRequest: store.cameraMoveRequest,
                userLocation: store.userLocation,
                onViewportChanged: { viewport in
                    store.send(.viewportChanged(viewport))
                },
                onCameraMoveRequestHandled: {
                    store.send(.cameraMoveRequestHandled)
                },
                onMarkerTapped: { id in
                    store.send(.markerTapped(id))
                }
            )
            .ignoresSafeArea()

            mapFloatingControls

            if store.showsResearchButton {
                researchButton
                    .padding(.top, 12)
            }
        }
        .onAppear {
            store.send(.mapAppeared)
        }
    }

    private var mapFloatingControls: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                myLocationButton
                    .padding(.trailing, mapFloatingControlTrailingPadding)
                    .padding(.bottom, mapFloatingControlBottomPadding)
            }
        }
    }

    private var myLocationButton: some View {
        Button {
            store.send(.myLocationButtonTapped)
        } label: {
            Image("myLocationButton")
                .resizable()
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private var mapFloatingControlTrailingPadding: CGFloat {
        20
    }

    private var mapFloatingControlBottomPadding: CGFloat {
        20
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
