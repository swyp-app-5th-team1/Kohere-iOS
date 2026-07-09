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
        case account(AccountFeature)
        case profileEdit(ProfileEditFeature)
        case promoteRoomWeb(PromoteRoomWebFeature)
        case setting(SettingFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var userType: UserType?
        var userProfile: UserProfile?
    }

    enum Action {
        case path(StackActionOf<Path>)
        case navigationLanguageTapped
        case navigationSettingTapped
        case editProfileTapped
        case promoteRoomTapped
        case userProfileUpdated(UserProfile)
        case popupRequested(AppPopup)
        case logoutConfirmed
        case deleteAccountConfirmed
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .path(.element(id: _, action: .account(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .account(.popupRequested(popup)))):
                return .send(.popupRequested(popup))

            case .path(.element(id: _, action: .profileEdit(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .profileEdit(.delegate(.profileUpdated(userProfile))))):
                _ = state.path.popLast()
                return .send(.userProfileUpdated(userProfile))

            case .path(.element(id: _, action: .promoteRoomWeb(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .setting(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .setting(.popupRequested(popup)))):
                return .send(.popupRequested(popup))

            case .path(.element(id: _, action: .setting(.settingItemTapped(.account)))):
                state.path.append(
                    .account(
                        AccountFeature.State(
                            userType: state.userType ?? .unknown,
                            userProfile: state.userProfile
                        )
                    )
                )
                return .none

            case .navigationLanguageTapped:
                return .none

            case .navigationSettingTapped:
                state.path.append(.setting(SettingFeature.State()))
                return .none

            case .editProfileTapped:
                state.path.append(.profileEdit(ProfileEditFeature.State(userProfile: state.userProfile)))
                return .none

            case .promoteRoomTapped:
                state.path.append(.promoteRoomWeb(PromoteRoomWebFeature.State()))
                return .none

            case let .userProfileUpdated(userProfile):
                state.userType = userProfile.userType
                state.userProfile = userProfile

                for id in state.path.ids {
                    state.path[id: id, case: \.account]?.userType = userProfile.userType
                    state.path[id: id, case: \.account]?.userProfile = userProfile
                }

                return .none

            case .popupRequested, .logoutConfirmed, .deleteAccountConfirmed:
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MoreFeature.Path.State: Equatable {}
