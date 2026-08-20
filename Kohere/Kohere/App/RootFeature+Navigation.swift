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

        case let .diagnosis(id, filter):
            return .send(.map(.diagnosisResultRequested(diagnosisID: id, filter: filter)))
        }
    }

    func openListingMapPreview(coordinate: MapCoordinate, state: inout State) -> Effect<Action> {
        state.selectedTab = .map
        return .send(.map(.listingMapPreviewRequested(coordinate)))
    }

    func handlePopupRoute(_ route: AppPopup.Route, state: inout State) -> Effect<Action> {
        switch route {
        case .signIn:
            state.login = LoginFeature.State()
            state.isAuthenticationFlowPresented = true
            return .none

        case .home:
            state.selectedTab = .home
            return .none

        case .logout:
            return .send(.more(.logoutConfirmed))

        case .deleteAccount:
            return .send(.more(.deleteAccountConfirmed))

        case let .reportBooking(bookingID):
            return .send(.chat(.reportDetailsRequested(roomID: bookingID)))

        case let .blockBooking(bookingID):
            return .send(.chat(.swipeActionConfirmed(.block, roomID: bookingID)))

        case let .deleteBooking(bookingID):
            return .send(.chat(.swipeActionConfirmed(.delete, roomID: bookingID)))

        case .dismissListingDetail:
            switch state.selectedTab {
            case .home:
                _ = state.home.path.popLast()
            case .map:
                _ = state.map.path.popLast()
            case .more:
                _ = state.more.path.popLast()
            case .community, .chat:
                break
            }
            return .none

        case let .confirmLanguageChange(language):
            return .send(.more(.languageChangeConfirmed(language)))
        }
    }
}
