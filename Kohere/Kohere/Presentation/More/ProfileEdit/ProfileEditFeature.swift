//
//  ProfileEditFeature.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ProfileEditFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var nickname: String = "Nickname"
        var email: String = "user@example.com"

        var firstName: String = ""
        var lastName: String = ""
        var selectedNationality: DropdownMenuOption?
        var selectedGender: DropdownMenuOption?
        var selectedVisa: DropdownMenuOption?
        var selectedOccupation: DropdownMenuOption?

        var isSaveButtonEnabled: Bool {
            !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedVisa != nil
            && selectedOccupation != nil
        }
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case backButtonTapped
        case saveButtonTapped
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

            case .saveButtonTapped:
                return .none
            }
        }
    }
}
