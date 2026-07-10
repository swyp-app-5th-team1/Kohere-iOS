//
//  RootFeature+Navigation.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture

extension RootFeature {
    func openMap(diagnosisID: String?, state: inout State) -> Effect<Action> {
        state.selectedTab = .map

        guard let diagnosisID,
              let diagnosisID = Int(diagnosisID)
        else {
            return .send(.map(.locationSearchStarted))
        }

        return .send(.map(.diagnosisResultRequested(diagnosisID: diagnosisID)))
    }

    func openMap(coordinate: MapCoordinate, state: inout State) -> Effect<Action> {
        state.selectedTab = .map
        return .send(.map(.listingLocationRequested(coordinate)))
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
