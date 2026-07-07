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
        case termsOfService
        case privacyPolicy
        case marketingAgreement
    }

    @ObservableState
    struct State: Equatable {
        var appVersion: String

        init(appVersion: String = Bundle.main.shortVersionString) {
            self.appVersion = appVersion
        }
    }

    enum Action: Equatable {
        case backButtonTapped
        case settingItemTapped(SettingItem)
        case logoutButtonTapped
        case popupRequested(AppPopup)
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped,
                 .settingItemTapped:
                return .none

            case .logoutButtonTapped:
                return .send(.popupRequested(Self.logoutPopup))

            case .popupRequested:
                return .none
            }
        }
    }
}

private extension SettingFeature {
    static var logoutPopup: AppPopup {
        .action(
            AppPopup.Action(
                message: "로그아웃 시 원활한 이용이 어려울 수 있습니다.\n그럼에도 로그아웃하시겠습니까?",
                primaryTitle: "뒤로가기",
                secondaryTitle: "로그아웃하기",
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
