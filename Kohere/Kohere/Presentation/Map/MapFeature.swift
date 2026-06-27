//
//  MapFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

enum MapLocationAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum MapSheetMode: Equatable {
    case listingList
    case selectedListing
}

@Reducer
struct MapFeature {
    @Dependency(\.locationClient)
    var locationClient

    @Reducer
    enum Path {
    }

    @ObservableState
    struct State: Equatable {
        // navigation
        var path = StackState<Path.State>()

        // 매물/마커 표시 상태
        var markers: [MapMarkerItem] = [
            MapMarkerItem(
                id: "hongdae-station",
                coordinate: MapCoordinate(latitude: 37.557192, longitude: 126.925381)
            ),
            MapMarkerItem(
                id: "sinchon-station",
                coordinate: MapCoordinate(latitude: 37.555134, longitude: 126.936893)
            ),
            MapMarkerItem(
                id: "hapjeong-station",
                coordinate: MapCoordinate(latitude: 37.549463, longitude: 126.913739)
            )
        ]
        var selectedMarkerID: String?
        var listings: [ListingItemModel] = .mapMockList

        // 지도 viewport / 재검색 상태
        var currentViewport: MapViewport?
        var lastSearchedViewport: MapViewport?
        var showsResearchButton = false

        // 바텀시트 / 필터 상태
        var sheetMode: MapSheetMode = .listingList
        var isFilterPresented = false
        var appliedFilter = MapFilterState()
        var editingFilter = MapFilterState()
        var appliedFilterSource: MapFilterApplicationSource = .manual

        // 위치 권한 / 현재 위치 / 카메라 이동 요청 상태
        var locationAuthorization: MapLocationAuthorization = .notDetermined
        var userLocation: MapCoordinate?
        var cameraMoveRequest: MapCoordinate?
        var hasMovedToInitialUserLocation = false
    }

    enum Action {
        case mapAppeared
        case mapDismissed
        case locationAuthorizationChanged(MapLocationAuthorization)
        case userLocationUpdated(MapCoordinate)
        case myLocationButtonTapped
        case cameraMoveRequestHandled
        case markerTapped(String)
        case researchButtonTapped
        case viewportChanged(MapViewport)
        case path(StackActionOf<Path>)
        case listingTapped(String)
        case listingLikeButtonTapped(Int)
        case selectedListingCloseButtonTapped

        // 필터 관련
        case filterButtonTapped
        case filterDismissed
        case filterOptionTapped(MapFilterOption)
        case filterPropertyTypeTapped(MapPropertyType)
        case monthlyRentMinimumChanged(Int)
        case monthlyRentMaximumChanged(Int)
        case depositMinimumChanged(Int)
        case depositMaximumChanged(Int)
        case filterApplyButtonTapped
        case filterResetButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .mapAppeared:
                return .run { [locationClient] send in
                    let authorization = await locationClient.requestAuthorization()
                    await send(.locationAuthorizationChanged(authorization))

                    guard case .authorized = authorization else { return }

                    let updates = await locationClient.locationUpdates()
                    for await coordinate in updates {
                        await send(.userLocationUpdated(coordinate))
                    }
                }
                .cancellable(id: "MapFeature.locationUpdates", cancelInFlight: true)

            case .mapDismissed:
                return .cancel(id: "MapFeature.locationUpdates")

            case let .locationAuthorizationChanged(authorization):
                state.locationAuthorization = authorization

                switch authorization {
                case .authorized:
                    break

                case .notDetermined, .denied, .restricted:
                    state.userLocation = nil
                    state.hasMovedToInitialUserLocation = false
                }

                return .none

            case let .userLocationUpdated(coordinate):
                state.userLocation = coordinate

                if !state.hasMovedToInitialUserLocation {
                    state.cameraMoveRequest = coordinate
                    state.hasMovedToInitialUserLocation = true
                }

                return .none

            case .myLocationButtonTapped:
                guard state.locationAuthorization == .authorized else { return .none }
                guard let userLocation = state.userLocation else { return .none }
                state.cameraMoveRequest = userLocation
                return .none

            case .cameraMoveRequestHandled:
                state.cameraMoveRequest = nil
                return .none

            case let .markerTapped(id):
                guard state.selectedMarkerID != id else { return .none }
                state.selectedMarkerID = id
                state.sheetMode = .selectedListing
                return .none

            case .researchButtonTapped:
                state.lastSearchedViewport = state.currentViewport
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                state.showsResearchButton = false
                return .none

            case let .viewportChanged(viewport):
                state.currentViewport = viewport
                guard let lastSearchedViewport = state.lastSearchedViewport else {
                    state.lastSearchedViewport = viewport
                    state.showsResearchButton = false
                    return .none
                }

                state.showsResearchButton = lastSearchedViewport != viewport
                return .none

            case .path:
                return .none

            case let .listingTapped(id):
                state.selectedMarkerID = id
                state.sheetMode = .selectedListing
                return .none

            case let .listingLikeButtonTapped(id):
                guard let index = state.listings.firstIndex(where: { $0.id == id }) else { return .none }
                state.listings[index].isLiked.toggle()
                return .none

            case .selectedListingCloseButtonTapped:
                state.selectedMarkerID = nil
                state.sheetMode = .listingList
                return .none

            case .filterButtonTapped:
                state.editingFilter = state.appliedFilter
                state.isFilterPresented = true
                return .none

            case .filterDismissed:
                state.editingFilter = state.appliedFilter
                state.isFilterPresented = false
                return .none

            case let .filterOptionTapped(option):
                state.editingFilter.toggleOption(option)
                return .none

            case let .filterPropertyTypeTapped(property):
                state.editingFilter.togglePropertyType(property)
                return .none

            case let .monthlyRentMinimumChanged(minimum):
                state.editingFilter.updateMonthlyRentMinimum(minimum)
                return .none

            case let .monthlyRentMaximumChanged(maximum):
                state.editingFilter.updateMonthlyRentMaximum(maximum)
                return .none

            case let .depositMinimumChanged(minimum):
                state.editingFilter.updateDepositMinimum(minimum)
                return .none

            case let .depositMaximumChanged(maximum):
                state.editingFilter.updateDepositMaximum(maximum)
                return .none

            case .filterApplyButtonTapped:
                state.appliedFilter = state.editingFilter
                if state.editingFilter.isDefault {
                    state.appliedFilterSource = .manual
                }
                state.isFilterPresented = false
                return .none

            case .filterResetButtonTapped:
                state.editingFilter = MapFilterState()
                return .none
            }
        }
    }
}

extension MapFeature.Path.State: Equatable {}

private extension Array where Element == ListingItemModel {
    static let mapMockList: [ListingItemModel] = [
        ListingItemModel(
            id: 1,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$355~398/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: false
        ),
        ListingItemModel(
            id: 2,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$355~398/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: true
        ),
        ListingItemModel(
            id: 3,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$355~398/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: false
        ),
        ListingItemModel(
            id: 4,
            formattedPrice: "₩380~400K/mo",
            formattedUsdPrice: "≈$355~398/mo",
            detailsDescription: "Dep. ₩200K · Maint. ₩20K",
            locationDescription: "8-min walk Hongdae Sta.",
            typeTag: "Goshiwon",
            period: "1 mo~",
            isLiked: false
        )
    ]
}
