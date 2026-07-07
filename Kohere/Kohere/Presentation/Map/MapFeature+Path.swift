//
//  MapFeature+Path.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

extension MapFeature {
    func handlePathAction(
        _ action: StackActionOf<Path>,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .element(id: _, action: .listingDetail(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .chatBot(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .search(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .search(.bannerTapped)):
            state.path.append(.chatBot(ChatBotFeature.State()))
            return .none

        case let .element(id: _, action: .search(.placeResultTapped(placeResult))):
            _ = state.path.popLast()
            return .send(.placeSearchResultSelected(placeResult))

        default:
            return .none
        }
    }
}
