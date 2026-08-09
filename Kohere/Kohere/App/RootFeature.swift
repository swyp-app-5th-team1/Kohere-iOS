//
//  RootFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RootFeature {
    @Dependency(\.continuousClock)
    var clock
    @Dependency(\.keychainClient)
    var keychainClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient
    @Dependency(\.reissueTokenUseCase)
    var reissueTokenUseCase
    @Dependency(\.logoutUseCase)
    var logoutUseCase
    @Dependency(\.fetchCurrentUserUseCase)
    var fetchCurrentUserUseCase
    @Dependency(\.updateProfileUseCase)
    var updateProfileUseCase
    @Dependency(\.deleteCurrentUserUseCase)
    var deleteCurrentUserUseCase

    enum Action {
        case onAppear, splashMinimumDurationElapsed, mainTabAppeared
        case storedAuthLoaded(Auth?, OnboardingUserType?)
        case authSessionExpired(AuthSessionExpirationContext?)
        case currentUserResponse(Result<UserProfile, Error>)
        case logoutResponse(Result<Void, Error>)
        case deleteAccountResponse(Result<Void, Error>)
        case deleteAccountLocalCleanupResponse(Result<Void, Error>)
        case login(LoginFeature.Action), saveAuthResponse(Result<Auth, Error>)
        case onboardingLanguageUpdateResponse(AppLanguage, Result<UserProfile, Error>)
        case onboarding(OnboardingFeature.Action)
        case selectedTabChanged(AppTab), popupPresented(AppPopup)
        case popupNoticeConfirmButtonTapped, popupActionPrimaryButtonTapped, popupActionSecondaryButtonTapped
        case home(HomeFeature.Action), community(CommunityFeature.Action), map(MapFeature.Action)
        case chat(ChatFeature.Action), more(MoreFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.community, action: \.community) {
            CommunityFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.chat, action: \.chat) {
            ChatFeature()
        }
        Scope(state: \.more, action: \.more) {
            MoreFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear,
                 .splashMinimumDurationElapsed,
                 .storedAuthLoaded,
                 .authSessionExpired,
                 .mainTabAppeared,
                 .currentUserResponse,
                 .login(.loginAuthStored),
                 .login(.userTypeSelected),
                 .onboarding(.delegate(.completed)),
                 .saveAuthResponse(.success),
                 .onboardingLanguageUpdateResponse:
                return reduceLifecycle(action, state: &state)

            case .home(.delegate(.authenticationRequired)),
                 .map(.listingLikeButtonTapped),
                 .more(.savedListingsTapped),
                 .more(.recentlyViewedListingsTapped):
                return presentAuthenticationGateIfNeeded(state: &state)

            case .map(.path(.element(id: _, action: .listingDetail(.likeButtonTapped)))),
                 .more(.path(.element(id: _, action: .listingDetail(.likeButtonTapped)))):
                return presentAuthenticationGateIfNeeded(state: &state)

            case .saveAuthResponse(.failure):
                state.popup = OnboardingErrorPopup.make(context: .saveAuthentication, language: state.appLanguage)
                return .none

            case let .onboarding(.delegate(.popupRequested(popup))):
                state.popup = popup
                return .none

            case let .home(.delegate(.mapRequested(request))):
                state.home.path.removeAll()
                return openMap(request: request, state: &state)

            case let .home(.delegate(.mapPlaceSearchRequested(placeResult))):
                state.home.path.removeAll()
                state.selectedTab = .map
                return .send(.map(.placeSearchResultSelected(placeResult)))

            case let .home(.delegate(.listingMapPreviewRequested(coordinate))):
                state.home.path.removeAll()
                return openListingMapPreview(coordinate: coordinate, state: &state)

            case .home(.delegate(.chatTabRequested)):
                state.home.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .home(.delegate(.popupRequested(popup))):
                state.popup = popup
                return .none

            case let .home(.delegate(.favoriteStatusChanged(listingID, status))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none
                
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                if state.authInfo?.onboardingRequired != false,
                   tab == .chat || tab == .more {
                    return presentAuthenticationGateIfNeeded(state: &state, returnsToHomeOnDismiss: true)
                }
                return .none

            case let .popupPresented(popup):
                state.popup = popup
                return .none

            case .popupNoticeConfirmButtonTapped:
                guard case let .notice(popup) = state.popup else { return .none }
                state.popup = nil
                guard let route = popup.confirmRoute else { return .none }
                return handlePopupRoute(route, state: &state)

            case .popupActionPrimaryButtonTapped:
                guard case let .action(popup) = state.popup else { return .none }
                state.popup = nil
                guard let route = popup.primaryRoute else { return .none }
                return handlePopupRoute(route, state: &state)

            case .popupActionSecondaryButtonTapped:
                guard case let .action(popup) = state.popup else { return .none }
                state.popup = nil
                guard let route = popup.secondaryRoute else { return .none }
                return handlePopupRoute(route, state: &state)

            case let .map(.path(.element(id: _, action: .chatBot(.mapRequested(request))))):
                state.map.path.removeAll()
                return openMap(request: request, state: &state)

            case .map(.path(.element(id: _, action: .listingApplication(.delegate(.chatTabRequested))))):
                state.map.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .map(.path(.element(id: _, action: .search(.popupRequested(popup))))):
                state.popup = popup
                return .none

            case let .map(.path(.element(id: _, action: .listingDetail(.popupRequested(popup))))),
                 let .more(.path(.element(id: _, action: .listingDetail(.popupRequested(popup))))):
                state.popup = popup
                return .none

            case let .map(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.map.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .chat(.mapRequested(request)):
                state.chat.path.removeAll()
                return openMap(request: request, state: &state)

            case let .chat(.popupRequested(popup)):
                state.popup = popup
                return .none

            case let .more(.popupRequested(popup)):
                state.popup = popup
                return .none

            case let .more(.listingMapPreviewRequested(coordinate)):
                state.more.path.removeAll()
                return openListingMapPreview(coordinate: coordinate, state: &state)

            case .more(.chatTabRequested):
                state.more.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .more(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.more.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.path(.element(id: _, action: .savedListings(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.path(.element(id: _, action: .recentlyViewedList(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.userProfileUpdated(userProfile)):
                if userProfile.userType == .landlord,
                   state.appLanguage != .korean {
                    try? userDefaultsClient.save(AppLanguage.korean.apiCode, for: .appLanguage)
                    let selectedTab = state.selectedTab
                    let cancellation = resetMainContent(language: .korean, userProfile: userProfile,
                                                        selectedTab: selectedTab, state: &state)
                    return .concatenate(cancellation, .merge(.send(.home(.onAppear)), .send(.more(.onAppear))))
                }

                state.currentUser = userProfile
                state.home.userType = userProfile.userType
                state.map.userType = userProfile.userType
                let didUpdateChatRole = state.chat.applyUserType(userProfile.userType)
                var effects: [Effect<Action>] = [
                    .send(.home(.onAppear))
                ]

                if didUpdateChatRole, state.selectedTab == .chat {
                    effects.append(.send(.chat(.onAppear)))
                }

                return .merge(effects)

            case let .more(.languageUpdateResponse(language, .success(userProfile))):
                let resolvedLanguage = userProfile.userType == .landlord ? AppLanguage.korean : language
                try? userDefaultsClient.save(resolvedLanguage.apiCode, for: .appLanguage)
                let cancellation = resetMainContent(language: resolvedLanguage, userProfile: userProfile, state: &state)
                return .concatenate(cancellation, .merge(.send(.home(.onAppear)), .send(.more(.onAppear))))

            case .more(.logoutConfirmed):
                guard !state.isLogoutRequesting else { return .none }
                state.isLogoutRequesting = true
                let logoutUseCase = logoutUseCase

                return .run { send in
                    do {
                        try await logoutUseCase.execute()
                        await send(.logoutResponse(.success(())))
                    } catch {
                        await send(.logoutResponse(.failure(error)))
                    }
                }
                .cancellable(id: "RootFeature.logout", cancelInFlight: true)

            case .logoutResponse(.success):
                return completeLogout(state: &state)

            case let .logoutResponse(.failure(error)):
                if case LogoutError.localAuthCleanupFailed = error {
                    state.isLogoutRequesting = false
                    state.popup = .notice(AppPopup.Notice(message: state.appLanguage.localized(.settingsLogoutFailure)))
                    return .none
                }

                return completeLogout(state: &state)

            case .more(.deleteAccountConfirmed):
                guard !state.isDeleteAccountRequesting else { return .none }
                state.isDeleteAccountRequesting = true
                let deleteCurrentUserUseCase = deleteCurrentUserUseCase

                return .run { send in
                    do {
                        try await deleteCurrentUserUseCase.execute()
                        await send(.deleteAccountResponse(.success(())))
                    } catch {
                        await send(.deleteAccountResponse(.failure(error)))
                    }
                }
                .cancellable(id: "RootFeature.deleteAccount", cancelInFlight: true)

            case .deleteAccountResponse(.success):
                try? userDefaultsClient.save(true, for: .requiresAuthCleanup)
                let keychainClient = keychainClient

                return .run { send in
                    do {
                        try keychainClient.delete(for: .auth)
                        await send(.deleteAccountLocalCleanupResponse(.success(())))
                    } catch {
                        await send(.deleteAccountLocalCleanupResponse(.failure(error)))
                    }
                }

            case .deleteAccountResponse(.failure):
                state.isDeleteAccountRequesting = false
                state.popup = .notice(AppPopup.Notice(message: state.appLanguage.localized(.settingsWithdrawalFailure)))
                return .none

            case .deleteAccountLocalCleanupResponse(.success):
                userDefaultsClient.delete(for: .requiresAuthCleanup)
                return completeLogout(state: &state)

            case .deleteAccountLocalCleanupResponse(.failure):
                return completeLogout(state: &state)
                
            case .login, .onboarding, .home, .community, .map, .chat, .more:
                return .none
            }
        }
    }

}

extension RootFeature {
    func presentAuthenticationGateIfNeeded(state: inout State, returnsToHomeOnDismiss: Bool = false) -> Effect<Action> {
        guard state.authInfo?.onboardingRequired != false else { return .none }

        state.popup = .action(
            AppPopup.Action(message: state.appLanguage.localized(.authGateMessage), primaryTitle: state.appLanguage.localized(.authGateSignIn),
                            secondaryTitle: state.appLanguage.localized(.authGateNotNow), primaryRoute: .signIn, secondaryRoute: returnsToHomeOnDismiss ? .home : nil)
        )
        return .none
    }

    @discardableResult
    func resetMainContent(language: AppLanguage, userProfile: UserProfile, selectedTab: AppTab = .more, state: inout State) -> Effect<Action> {
        state.appLanguage = language
        state.currentUser = userProfile
        state.selectedTab = selectedTab
        state.popup = nil

        state.home = HomeFeature.State(userType: userProfile.userType, appLanguage: language)
        state.community = CommunityFeature.State()

        state.map = MapFeature.State(appLanguage: language)
        state.map.userType = userProfile.userType

        state.chat = ChatFeature.State(appLanguage: language)
        _ = state.chat.applyUserType(userProfile.userType)

        state.more = MoreFeature.State()
        state.more.userType = userProfile.userType
        state.more.userProfile = userProfile
        state.more.selectedLanguage = language

        return cancelHomeEffects()
    }
}
