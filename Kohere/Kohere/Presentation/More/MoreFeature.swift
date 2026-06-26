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
        case profileEdit(ProfileEditFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action {
        case path(StackActionOf<Path>)
        case navigationLanguageTapped
        case navigationSettingTapped
        case editProfileTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .path(.element(id: _, action: .profileEdit(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .navigationLanguageTapped, .navigationSettingTapped:
                return .none

            case .editProfileTapped:
                state.path.append(.profileEdit(ProfileEditFeature.State()))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MoreFeature.Path.State: Equatable {}
