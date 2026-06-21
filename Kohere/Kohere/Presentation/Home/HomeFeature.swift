//
//  HomeFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

@Reducer
struct HomeFeature {
    @Reducer
    enum Path {
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action {
        case path(StackActionOf<Path>)
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .path:
                return .none
            }
        }
    }
}

extension HomeFeature.Path.State: Equatable {}
