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
        var language: AppLanguage = .english
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
                message: language.localized(.settingsWithdrawalConfirmMessage),
                primaryTitle: language.localized(.settingsPopupCancel),
                secondaryTitle: language.localized(.settingsWithdrawalConfirmAction),
                secondaryRoute: .deleteAccount
            )
        )
    }

}
