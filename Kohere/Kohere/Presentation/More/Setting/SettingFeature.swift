//
//  SettingFeature.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingFeature {
    enum SettingItem: Equatable {
        case account
        case notification
        case termsOfService
        case privacyPolicy
        case marketingAgreement
    }

    @ObservableState
    struct State: Equatable {
        var appVersion: String
        var language: AppLanguage

        init(
            appVersion: String = Bundle.main.shortVersionString,
            language: AppLanguage = .english
        ) {
            self.appVersion = appVersion
            self.language = language
        }
    }

    enum Action: Equatable {
        case backButtonTapped
        case settingItemTapped(SettingItem)
        case logoutButtonTapped
        case popupRequested(AppPopup)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped,
                 .settingItemTapped:
                return .none

            case .logoutButtonTapped:
                return .send(.popupRequested(Self.logoutPopup(language: state.language)))

            case .popupRequested:
                return .none
            }
        }
    }
}

private extension SettingFeature {
    static func logoutPopup(language: AppLanguage) -> AppPopup {
        .action(
            AppPopup.Action(
                message: language.localized(.settingsLogoutConfirmMessage),
                primaryTitle: language.localized(.settingsPopupCancel),
                secondaryTitle: language.localized(.settingsLogoutConfirmAction),
                secondaryRoute: .logout
            )
        )
    }

}

private extension Bundle {
    var shortVersionString: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
