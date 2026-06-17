//
//  MoreFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

@Reducer
struct MoreFeature {
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

extension MoreFeature.Path.State: Equatable {}
