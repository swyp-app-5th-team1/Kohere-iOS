//
//  AnnouncementsFeature.swift
//  Kohere
//
//  Created by Codex on 7/18/26.
//

import ComposableArchitecture

@Reducer
struct AnnouncementsFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action: Equatable {
        case backButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .none
            }
        }
    }
}
