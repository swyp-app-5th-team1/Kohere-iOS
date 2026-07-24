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
    
    @ObservableState
    struct State: Equatable {
        var authInfo: Auth?
        var currentUser: UserProfile?
        var appLanguage: AppLanguage = .systemDefault
        var isAuthLoading = true
        var isCurrentUserLoading = false
        var isLogoutRequesting = false
        var isDeleteAccountRequesting = false
        var isAuthenticationFlowPresented = false
        var login = LoginFeature.State()
        var onboarding = OnboardingFeature.State()
        var selectedTab: AppTab = .home
        var popup: AppPopup?
        var home = HomeFeature.State()
        var community = CommunityFeature.State()
        var map = MapFeature.State()
        var chat = ChatFeature.State()
        var more = MoreFeature.State()
    }
    
    enum Action {
        case onAppear
        case mainTabAppeared
        case storedAuthLoaded(Auth?, OnboardingUserType?)
        case authSessionExpired(AuthSessionExpirationContext?)
        case currentUserResponse(Result<UserProfile, Error>)
        case logoutResponse(Result<Void, Error>)
        case deleteAccountResponse(Result<Void, Error>)
        case deleteAccountLocalCleanupResponse(Result<Void, Error>)
        case login(LoginFeature.Action)
        case saveAuthResponse(Result<Auth, Error>)
        case onboardingLanguageUpdateResponse(AppLanguage, Result<UserProfile, Error>)
        case onboarding(OnboardingFeature.Action)
        case selectedTabChanged(AppTab)
        case popupPresented(AppPopup)
        case popupNoticeConfirmButtonTapped
        case popupActionPrimaryButtonTapped
        case popupActionSecondaryButtonTapped
        case home(HomeFeature.Action)
        case community(CommunityFeature.Action)
        case map(MapFeature.Action)
        case chat(ChatFeature.Action)
        case more(MoreFeature.Action)
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
            case .onAppear:
                let keychainClient = keychainClient
                let userDefaultsClient = userDefaultsClient
                let reissueTokenUseCase = reissueTokenUseCase
                let storedLanguageRawValue = try? userDefaultsClient.load(for: .appLanguage)
                let resolvedLanguage: AppLanguage
                if !state.isAuthLoading, state.authInfo == nil {
                    resolvedLanguage = .english
                } else {
                    resolvedLanguage = storedLanguageRawValue
                        .flatMap(AppLanguage.init(rawValue:)) ?? .systemDefault
                }
                state.appLanguage = resolvedLanguage
                state.onboarding.tenant?.appLanguage = resolvedLanguage
                state.home.appLanguage = resolvedLanguage
                state.map.appLanguage = resolvedLanguage
                state.chat.appLanguage = resolvedLanguage
                state.more.selectedLanguage = resolvedLanguage
                var effects: [Effect<Action>] = [
                    .run { send in
                        for await notification in NotificationCenter.default.notifications(named: .authSessionExpired) {
                            await send(.authSessionExpired(notification.object as? AuthSessionExpirationContext))
                        }
                    }
                    .cancellable(
                        id: "RootFeature.authSessionObserver",
                        cancelInFlight: true
                    )
                ]
                
                if state.authInfo == nil, state.isAuthLoading {
                    effects.append(
                        .run { send in
                            let hasLaunchedBefore = try userDefaultsClient.load(for: .hasLaunchedBefore) ?? false

                            let requiresAuthCleanup = try userDefaultsClient.load(for: .requiresAuthCleanup) ?? false
                            if requiresAuthCleanup {
                                do {
                                    try keychainClient.delete(for: .auth)
                                    userDefaultsClient.delete(for: .requiresAuthCleanup)
                                } catch {
                                    await send(.storedAuthLoaded(nil, nil))
                                    return
                                }
                            }

                            if !hasLaunchedBefore {
                                Self.logFirstLaunchAuthReset()
                                try keychainClient.delete(for: .auth)
                                try userDefaultsClient.save(true, for: .hasLaunchedBefore)
                            }

                            let auth = try keychainClient.load(for: .auth)
                            Self.logStoredAuthLoaded(auth != nil)
                            let pendingOnboardingUserTypeRawValue = try userDefaultsClient.load(for: .pendingOnboardingUserType)
                            let pendingOnboardingUserType = pendingOnboardingUserTypeRawValue.flatMap(OnboardingUserType.init(rawValue:))
                            let resolvedAuth = await Self.resolveStoredAuth(
                                auth,
                                keychainClient: keychainClient,
                                reissueToken: reissueTokenUseCase.execute
                            )
                            await send(.storedAuthLoaded(resolvedAuth, pendingOnboardingUserType))
                        } catch: { error, send in
                            Self.logStartupAuthLoadFailure(error)
                            await send(.storedAuthLoaded(nil, nil))
                        }
                    )
                }
                
                return .merge(effects)
                
            case let .storedAuthLoaded(auth, pendingOnboardingUserType):
                state.authInfo = auth
                state.isAuthLoading = false

                if auth == nil {
                    applyAppLanguage(.english, state: &state)
                }

                guard auth?.onboardingRequired == true else {
                    userDefaultsClient.delete(for: .pendingOnboardingUserType)
                    return .none
                }

                state.isAuthenticationFlowPresented = true

                if let pendingOnboardingUserType {
                    let defaultLanguage = defaultLanguage(for: pendingOnboardingUserType)
                    applyAppLanguage(defaultLanguage, state: &state)
                    state.onboarding = OnboardingFeature.State(
                        userType: pendingOnboardingUserType,
                        appLanguage: defaultLanguage,
                        socialName: auth?.name
                    )
                } else {
                    applyAppLanguage(.english, state: &state)
                    state.authInfo = nil
                    state.login.authInfo = auth
                    state.login.currentSheet = .userTypeSelect
                }

                return .none

            case let .authSessionExpired(context):
                Self.logSessionExpiration(context)
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                let appLanguage = AppLanguage.english
                state = State(appLanguage: appLanguage, isAuthLoading: false)
                state.isAuthenticationFlowPresented = true
                state.home.appLanguage = appLanguage
                state.map.appLanguage = appLanguage
                state.chat.appLanguage = appLanguage
                state.more.selectedLanguage = appLanguage
                return .cancel(id: "RootFeature.fetchCurrentUser")

            case .mainTabAppeared:
                return fetchCurrentUserIfNeeded(state: &state)

            case let .currentUserResponse(.success(user)):
                guard state.authInfo?.onboardingRequired == false else {
                    state.isCurrentUserLoading = false
                    return .none
                }

                state.isCurrentUserLoading = false
                let language = user.userType == .landlord ? AppLanguage.korean : user.appLanguage

                if user.userType == .landlord {
                    try? userDefaultsClient.save(AppLanguage.korean.rawValue, for: .appLanguage)
                }

                if let language,
                   language != state.appLanguage {
                    try? userDefaultsClient.save(language.rawValue, for: .appLanguage)
                    let selectedTab = state.selectedTab
                    resetMainContent(
                        language: language,
                        userProfile: user,
                        selectedTab: selectedTab,
                        state: &state
                    )
                    return .merge(
                        .send(.home(.onAppear)),
                        .send(.more(.onAppear))
                    )
                }

                return .send(.more(.userProfileUpdated(user)))

            case .currentUserResponse(.failure):
                state.isCurrentUserLoading = false
                return .none

            case let .login(.loginAuthStored(auth)):
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                userDefaultsClient.delete(for: .requiresAuthCleanup)
                state.authInfo = auth
                state.isAuthenticationFlowPresented = false
                return fetchCurrentUserIfNeeded(state: &state)
                
            case let .login(.userTypeSelected(userType)):
                guard state.login.isRequiredTermsAgreed,
                      let authInfo = state.login.authInfo else { return .none }
                let defaultLanguage = defaultLanguage(for: userType)
                try? userDefaultsClient.save(defaultLanguage.rawValue, for: .appLanguage)
                try? userDefaultsClient.save(userType.rawValue, for: .pendingOnboardingUserType)
                applyAppLanguage(defaultLanguage, state: &state)
                state.authInfo = authInfo
                state.onboarding = OnboardingFeature.State(
                    userType: userType,
                    appLanguage: defaultLanguage,
                    socialName: authInfo.name
                )
                return .none
                
            case let .onboarding(.onboardingResponse(.success(auth))):
                let keychainClient = keychainClient
                
                return .run { send in
                    try keychainClient.save(auth, for: .auth)
                    await send(.saveAuthResponse(.success(auth)))
                } catch: { error, send in
                    await send(.saveAuthResponse(.failure(error)))
                }
            
            case let .saveAuthResponse(.success(updatedAuthInfo)):
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                userDefaultsClient.delete(for: .requiresAuthCleanup)
                state.authInfo = updatedAuthInfo
                let language = defaultLanguage(for: state.onboarding.userType)
                applyAppLanguage(language, state: &state)
                let updateProfileUseCase = updateProfileUseCase

                return .run { send in
                    do {
                        let profile = try await updateProfileUseCase.execute(
                            UserProfileUpdate(lang: language.rawValue)
                        )
                        await send(.onboardingLanguageUpdateResponse(
                            language,
                            .success(profile)
                        ))
                    } catch {
                        await send(.onboardingLanguageUpdateResponse(
                            language,
                            .failure(error)
                        ))
                    }
                }

            case let .onboardingLanguageUpdateResponse(language, .success(userProfile)):
                try? userDefaultsClient.save(language.rawValue, for: .appLanguage)
                state.isAuthenticationFlowPresented = false
                let selectedTab = state.selectedTab
                resetMainContent(
                    language: language,
                    userProfile: userProfile,
                    selectedTab: selectedTab,
                    state: &state
                )
                return .merge(
                    .send(.home(.onAppear)),
                    .send(.more(.onAppear))
                )

            case .onboardingLanguageUpdateResponse(_, .failure):
                state.isAuthenticationFlowPresented = false
                return fetchCurrentUserIfNeeded(state: &state)

            case .home(.navigationHeartTapped),
                 .home(.navigationNoticeTapped),
                 .home(.seeAllListingsTapped),
                 .home(.likeButtonTapped),
                 .map(.listingLikeButtonTapped),
                 .more(.savedListingsTapped),
                 .more(.recentlyViewedListingsTapped):
                return presentAuthenticationGateIfNeeded(state: &state)

            case .home(.path(.element(id: _, action: .listingDetail(.likeButtonTapped)))),
                 .map(.path(.element(id: _, action: .listingDetail(.likeButtonTapped)))),
                 .more(.path(.element(id: _, action: .listingDetail(.likeButtonTapped)))):
                return presentAuthenticationGateIfNeeded(state: &state)

            case .saveAuthResponse(.failure):
                return .none

            case let .home(.mapRequested(request)):
                state.home.path.removeAll()
                return openMap(request: request, state: &state)

            case let .home(.mapPlaceSearchRequested(placeResult)):
                state.home.path.removeAll()
                state.selectedTab = .map
                return .send(.map(.placeSearchResultSelected(placeResult)))

            case let .home(.listingMapPreviewRequested(coordinate)):
                state.home.path.removeAll()
                return openListingMapPreview(coordinate: coordinate, state: &state)

            case .home(.chatTabRequested):
                state.home.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .home(.path(.element(id: _, action: .search(.popupRequested(popup))))):
                state.popup = popup
                return .none

            case let .home(.favoriteStatusResponse(listingID, .success(status))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.home.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: _, action: .savedListings(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: _, action: .recentlyViewedList(.favoriteStatusResponse(listingID, .success(status)))))):
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

            case let .home(.path(.element(id: _, action: .listingDetail(.popupRequested(popup))))),
                 let .map(.path(.element(id: _, action: .listingDetail(.popupRequested(popup))))),
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
                    try? userDefaultsClient.save(AppLanguage.korean.rawValue, for: .appLanguage)
                    let selectedTab = state.selectedTab
                    resetMainContent(language: .korean,
                        userProfile: userProfile,
                        selectedTab: selectedTab,
                        state: &state
                    )
                    return .merge(.send(.home(.onAppear)), .send(.more(.onAppear)))
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
                try? userDefaultsClient.save(resolvedLanguage.rawValue, for: .appLanguage)
                resetMainContent(language: resolvedLanguage,
                    userProfile: userProfile,
                    state: &state
                )
                return .merge(
                    .send(.home(.onAppear)),
                    .send(.more(.onAppear))
                )

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
                    state.popup = .notice(
                        AppPopup.Notice(
                            message: state.appLanguage.localized("settings.logout.failure")
                        )
                    )
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
                state.popup = .notice(
                    AppPopup.Notice(
                        message: state.appLanguage.localized("settings.withdrawal.failure")
                    )
                )
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
    func defaultLanguage(for userType: OnboardingUserType) -> AppLanguage {
        switch userType {
        case .tenant:
            .english
        case .landlord:
            .korean
        }
    }

    func applyAppLanguage(_ language: AppLanguage, state: inout State) {
        state.appLanguage = language
        state.onboarding.tenant?.appLanguage = language
        state.home.appLanguage = language
        state.map.appLanguage = language
        state.chat.appLanguage = language
        state.more.selectedLanguage = language
    }

    func presentAuthenticationGateIfNeeded(state: inout State, returnsToHomeOnDismiss: Bool = false) -> Effect<Action> {
        guard state.authInfo?.onboardingRequired != false else { return .none }

        state.popup = .action(
            AppPopup.Action(
                message: state.appLanguage.localized("authGate.message"),
                primaryTitle: state.appLanguage.localized("authGate.signIn"),
                secondaryTitle: state.appLanguage.localized("authGate.notNow"),
                primaryRoute: .signIn,
                secondaryRoute: returnsToHomeOnDismiss ? .home : nil
            )
        )
        return .none
    }

    func resetMainContent(
        language: AppLanguage,
        userProfile: UserProfile,
        selectedTab: AppTab = .more,
        state: inout State
    ) {
        state.appLanguage = language
        state.currentUser = userProfile
        state.selectedTab = selectedTab
        state.popup = nil

        state.home = HomeFeature.State(
            userType: userProfile.userType,
            appLanguage: language
        )
        state.community = CommunityFeature.State()

        state.map = MapFeature.State(appLanguage: language)
        state.map.userType = userProfile.userType

        state.chat = ChatFeature.State(appLanguage: language)
        _ = state.chat.applyUserType(userProfile.userType)

        state.more = MoreFeature.State()
        state.more.userType = userProfile.userType
        state.more.userProfile = userProfile
        state.more.selectedLanguage = language
    }
}
