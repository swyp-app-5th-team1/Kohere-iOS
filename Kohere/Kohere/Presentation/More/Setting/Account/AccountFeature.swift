//
//  AccountFeature.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

@Reducer
struct AccountFeature {
    @ObservableState
    struct State: Equatable {
        let userType: UserType
        let userProfile: UserProfile?
    }

    enum Action: Equatable {
        case backButtonTapped
        case deleteAccountButtonTapped
        case popupRequested(AppPopup)
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .none

            case .deleteAccountButtonTapped:
                return .send(.popupRequested(Self.deleteAccountPopup))

            case .popupRequested:
                return .none
            }
        }
    }
}

private extension AccountFeature {
    static var deleteAccountPopup: AppPopup {
        .action(
            AppPopup.Action(
                message: "탈퇴 시 지금까지의 이용기록이 영구 삭제됩니다.\n그럼에도 삭제하시겠습니까?",
                primaryTitle: "뒤로가기",
                secondaryTitle: "탈퇴하기",
                secondaryRoute: .deleteAccount
            )
        )
    }
}
