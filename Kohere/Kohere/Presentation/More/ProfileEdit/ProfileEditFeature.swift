//
//  ProfileEditFeature.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import ComposableArchitecture

@Reducer
struct ProfileEditFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var firstName: String = "Gil Dong"
        var lastName: String = "Hong"
        var selectedNationality: DropdownMenuOption? = DropdownMenuOption(option: "England")
        var selectedGender: DropdownMenuOption? = DropdownMenuOption(option: "Male")
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case backButtonTapped
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding:
                return .none

            case .backButtonTapped:
                return .none
            }
        }
    }
}
