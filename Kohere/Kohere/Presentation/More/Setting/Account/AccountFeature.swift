//
//  AccountFeature.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AccountFeature {
    @ObservableState
    struct State: Equatable {
        var userType: UserType
        var userProfile: UserProfile?
        var language: AppLanguage = .systemDefault
    }

    enum Action: Equatable {
        case backButtonTapped
        case deleteAccountButtonTapped
        case popupRequested(AppPopup)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case .deleteAccountButtonTapped:
                return .send(.popupRequested(Self.deleteAccountPopup(language: state.language)))

            case .popupRequested:
                return .none
            }
        }
    }
}

private extension AccountFeature {
    static func deleteAccountPopup(language: AppLanguage) -> AppPopup {
        .action(
            AppPopup.Action(
                message: localized("settings.withdrawal.confirmMessage", language: language),
                primaryTitle: localized("settings.popup.cancel", language: language),
                secondaryTitle: localized("settings.withdrawal.confirmAction", language: language),
                secondaryRoute: .deleteAccount
            )
        )
    }

    static func localized(_ key: String, language: AppLanguage) -> String {
        language.localized(key)
    }
}
