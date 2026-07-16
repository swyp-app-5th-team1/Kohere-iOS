//
//  RootFeature+Navigation.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture

extension RootFeature {
    func openMap(request: MapEntryRequest, state: inout State) -> Effect<Action> {
        state.selectedTab = .map

        switch request {
        case .browseListings:
            return .send(.map(.browseListingsRequested))

        case let .diagnosis(id):
            return .send(.map(.diagnosisResultRequested(diagnosisID: id)))
        }
    }

    func openListingMapPreview(
        coordinate: MapCoordinate,
        state: inout State
    ) -> Effect<Action> {
        state.selectedTab = .map
        return .send(.map(.listingMapPreviewRequested(coordinate)))
    }

    func handlePopupRoute(_ route: AppPopup.Route) -> Effect<Action> {
        switch route {
        case .logout:
            return .send(.more(.logoutConfirmed))

        case .deleteAccount:
            return .send(.more(.deleteAccountConfirmed))
        }
    }
}
