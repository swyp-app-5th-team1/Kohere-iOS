//
//  MapView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MapView: View {
    @Environment(
        \.scenePhase
    )
    private var scenePhase
    @Bindable var store: StoreOf<MapFeature>
    @State private var listingSheetDetent: MapListingSheetDetent = .minimum
    @GestureState private var listingSheetDragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let containerHeight = proxy.size.height
            let listingSheetVisibleHeight = displayedListingSheetVisibleHeight(
                containerHeight: containerHeight
            )
            let floatingControlBottomPadding = mapFloatingControlBottomPadding(
                listingSheetVisibleHeight: listingSheetVisibleHeight,
                containerHeight: containerHeight
            )

            ZStack(alignment: .bottom) {
                mapContent

                mapFloatingControls(bottomPadding: floatingControlBottomPadding)

                mapListingSheet(containerHeight: containerHeight)

                if store.sheetMode == .selectedListing,
                   let selectedListingItem = store.selectedListingItem {
                    mapSelectedListingSheet(item: selectedListingItem)
                }

                if store.isLocationPermissionDialogPresented {
                    locationPermissionDialogOverlay
                }
            }
            .animation(sheetAnimation, value: store.sheetMode)
            .animation(.easeInOut(duration: 0.2), value: store.isLocationPermissionDialogPresented)
        }
        .onAppear {
            store.send(.mapAppeared)
        }
        .onDisappear {
            store.send(.mapDismissed)
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            store.send(.mapAppeared)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isFilterPresented },
                set: { isPresented in
                    guard !isPresented else { return }
                    store.send(.filterDismissed)
                }
            )
        ) {
            MapFilterView(store: store)
        }
    }

    // MARK: - Subviews
    private var mapContent: some View {
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

            MapTopControlsView(
                showsResearchButton: store.showsResearchButton,
                onSearchTapped: {
                    store.send(.searchButtonTapped)
                },
                onResearchTapped: {
                    store.send(.researchButtonTapped)
                }
            )
                .padding(.top, 12)
        }
    }

    private func mapFloatingControls(bottomPadding: CGFloat) -> some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                diagnosisButton
                    .padding(.leading, mapFloatingControlHorizontalPadding)

                Spacer()

                myLocationButton
                    .padding(.trailing, mapFloatingControlHorizontalPadding)
            }
            .padding(.bottom, bottomPadding)
        }
    }

    private var diagnosisButton: some View {
        let variant: MapDiagnosisButton.Variant = store.appliedFilterSource == .diagnosis
            ? .matches
            : .discovery
        let isExpanded = store.appliedFilterSource == .diagnosis
            ? store.isDiagnosisMatchesButtonExpanded
            : store.isDiagnosisButtonExpanded

        return MapDiagnosisButton(
            variant: variant,
            isExpanded: isExpanded,
            action: {
                store.send(.diagnosisButtonTapped)
            },
            closeAction: {
                store.send(.diagnosisButtonCloseButtonTapped)
            }
        )
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

    private var locationPermissionDialogOverlay: some View {
        ZStack {
            Color.materialDimmer
                .ignoresSafeArea()

            LocationPermissionDialog(
                onCloseTapped: {
                    store.send(.locationPermissionDialogCloseButtonTapped)
                },
                onSettingsTapped: {
                    store.send(.locationPermissionDialogSettingsButtonTapped)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .zIndex(10)
    }

    private var mapFloatingControlHorizontalPadding: CGFloat {
        20
    }

    private var mapFloatingControlSheetSpacing: CGFloat {
        16
    }

    private func mapListingSheet(containerHeight: CGFloat) -> some View {
        let maximumHeight = listingSheetHeight(for: .maximum, containerHeight: containerHeight)
        let displayedOffset = displayedListingSheetOffset(containerHeight: containerHeight)

        return MapListingSheetView(
            store: store,
            contentBottomPadding: listingSheetContentBottomPadding
        )
            .frame(height: maximumHeight)
            .offset(
                y: store.sheetMode == .selectedListing
                ? maximumHeight + tabBarCoveredHeight + hiddenSheetExtraOffset
                : displayedOffset
            )
            .allowsHitTesting(store.sheetMode == .listingList)
            .gesture(
                listingSheetDragGesture(containerHeight: containerHeight),
                including: store.sheetMode == .listingList ? .all : .none
            )
            .animation(sheetAnimation, value: listingSheetDetent)
    }

    private func mapSelectedListingSheet(item: ListingItemModel) -> some View {
        MapSelectedListingSheetView(
            title: store.selectedListingTitle,
            item: item,
            onCardTapped: {
                store.send(.selectedListingCardTapped)
            },
            onLikeTapped: {
                store.send(.listingLikeButtonTapped(item.listingID))
            },
            onCloseButtonTapped: {
                store.send(.selectedListingCloseButtonTapped)
            }
        )
        .frame(height: selectedListingSheetHeight)
        .clipped()
        .offset(y: tabBarCoveredHeight)
        .transition(.move(edge: .bottom))
    }

    // MARK: - Sheet Layout
    private var selectedListingSheetHeight: CGFloat {
        266
    }

    private var hiddenSheetExtraOffset: CGFloat {
        40
    }

    private var tabBarCoveredHeight: CGFloat {
        78
    }

    private var listingSheetBaseContentBottomPadding: CGFloat {
        104
    }

    private var listingSheetContentBottomPadding: CGFloat {
        switch listingSheetDetent {
        case .minimum, .maximum:
            listingSheetBaseContentBottomPadding
        case .medium:
            listingSheetBaseContentBottomPadding + tabBarCoveredHeight * 2
        }
    }

    private var sheetAnimation: Animation {
        .spring(response: 0.44, dampingFraction: 0.9)
    }

    private var selectedListingVisibleHeight: CGFloat {
        selectedListingSheetHeight - tabBarCoveredHeight
    }

    private func mapFloatingControlBottomPadding(
        listingSheetVisibleHeight: CGFloat,
        containerHeight: CGFloat
    ) -> CGFloat {
        let sheetHeight: CGFloat

        switch store.sheetMode {
        case .listingList:
            let mediumHeight = self.listingSheetHeight(
                for: .medium,
                containerHeight: containerHeight
            )
            sheetHeight = min(listingSheetVisibleHeight, mediumHeight)
        case .selectedListing:
            sheetHeight = selectedListingVisibleHeight
        }

        return sheetHeight + mapFloatingControlSheetSpacing
    }

    private func listingSheetHeight(
        for detent: MapListingSheetDetent,
        containerHeight: CGFloat
    ) -> CGFloat {
        switch detent {
        case .minimum:
            containerHeight * 0.20
        case .medium:
            containerHeight * 0.50
        case .maximum:
            containerHeight * 0.83
        }
    }

    private func displayedListingSheetVisibleHeight(containerHeight: CGFloat) -> CGFloat {
        let minimumHeight = listingSheetHeight(for: .minimum, containerHeight: containerHeight)
        let maximumHeight = listingSheetHeight(for: .maximum, containerHeight: containerHeight)
        let displayedOffset = displayedListingSheetOffset(containerHeight: containerHeight)

        return min(max(maximumHeight - displayedOffset, minimumHeight), maximumHeight)
    }

    private func displayedListingSheetOffset(containerHeight: CGFloat) -> CGFloat {
        let baseOffset = listingSheetOffset(
            for: listingSheetDetent,
            containerHeight: containerHeight
        )
        let draggedOffset = baseOffset + listingSheetDragTranslation
        let minimumOffset = listingSheetOffset(for: .maximum, containerHeight: containerHeight)
        let maximumOffset = listingSheetOffset(for: .minimum, containerHeight: containerHeight)

        return min(max(draggedOffset, minimumOffset), maximumOffset)
    }

    private func listingSheetOffset(
        for detent: MapListingSheetDetent,
        containerHeight: CGFloat
    ) -> CGFloat {
        listingSheetHeight(for: .maximum, containerHeight: containerHeight)
            - listingSheetHeight(for: detent, containerHeight: containerHeight)
    }

    private func listingSheetDragGesture(containerHeight: CGFloat) -> some Gesture {
        DragGesture()
            .updating($listingSheetDragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let baseHeight = listingSheetHeight(
                    for: listingSheetDetent,
                    containerHeight: containerHeight
                )
                let proposedHeight = baseHeight - value.translation.height

                listingSheetDetent = nearestListingSheetDetent(
                    proposedHeight: proposedHeight,
                    containerHeight: containerHeight
                )
            }
    }

    private func nearestListingSheetDetent(
        proposedHeight: CGFloat,
        containerHeight: CGFloat
    ) -> MapListingSheetDetent {
        MapListingSheetDetent.allCases.min { lhs, rhs in
            let lhsDistance = abs(
                listingSheetHeight(for: lhs, containerHeight: containerHeight) - proposedHeight
            )
            let rhsDistance = abs(
                listingSheetHeight(for: rhs, containerHeight: containerHeight) - proposedHeight
            )

            return lhsDistance < rhsDistance
        } ?? .medium
    }
}

private enum MapListingSheetDetent: CaseIterable {
    case minimum
    case medium
    case maximum
}
