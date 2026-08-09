//
//  RootFeature+Lifecycle.swift
//  Kohere
//

import ComposableArchitecture
import Foundation

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

    func reduceLifecycle(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .onAppear:
            let clock = clock
            let keychainClient = keychainClient
            let userDefaultsClient = userDefaultsClient
            let reissueTokenUseCase = reissueTokenUseCase
            let storedLanguageRawValue = try? userDefaultsClient.load(for: .appLanguage)
            let resolvedLanguage = (!state.isAuthLoading && state.authInfo == nil)
                ? AppLanguage.english
                : storedLanguageRawValue.flatMap(AppLanguage.init(apiCode:))
                    ?? AppLanguageResolver.resolveSystemLanguage()
            applyAppLanguage(resolvedLanguage, state: &state)
            var effects: [Effect<Action>] = [
                .run { send in
                    try await clock.sleep(for: .seconds(1.25))
                    await send(.splashMinimumDurationElapsed)
                }
                .cancellable(id: "RootFeature.splashMinimumDuration", cancelInFlight: true),
                .run { send in
                    for await notification in NotificationCenter.default.notifications(named: .authSessionExpired) {
                        await send(.authSessionExpired(notification.object as? AuthSessionExpirationContext))
                    }
                }
                .cancellable(id: "RootFeature.authSessionObserver", cancelInFlight: true)
            ]

            if state.authInfo == nil, state.isAuthLoading {
                effects.append(.run { send in
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
                    let userTypeRawValue = try userDefaultsClient.load(for: .pendingOnboardingUserType)
                    let userType = userTypeRawValue.flatMap(OnboardingUserType.init(rawValue:))
                    let resolvedAuth = await Self.resolveStoredAuth(
                        auth, keychainClient: keychainClient, reissueToken: reissueTokenUseCase.execute
                    )
                    await send(.storedAuthLoaded(resolvedAuth, userType))
                } catch: { error, send in
                    Self.logStartupAuthLoadFailure(error)
                    await send(.storedAuthLoaded(nil, nil))
                })
            }
            return .merge(effects)

        case .splashMinimumDurationElapsed:
            state.isSplashMinimumDurationElapsed = true
            return .none

        case let .storedAuthLoaded(auth, pendingOnboardingUserType):
            state.authInfo = auth
            state.isAuthLoading = false
            if auth == nil { applyAppLanguage(.english, state: &state) }
            guard auth?.onboardingRequired == true else {
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                return .none
            }
            state.isAuthenticationFlowPresented = true
            if let pendingOnboardingUserType {
                let language = defaultLanguage(for: pendingOnboardingUserType)
                applyAppLanguage(language, state: &state)
                state.onboarding = OnboardingFeature.State(
                    userType: pendingOnboardingUserType, appLanguage: language, socialName: auth?.name
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
            state = State(appLanguage: .english, isAuthLoading: false, isSplashMinimumDurationElapsed: true)
            state.isAuthenticationFlowPresented = true
            applyAppLanguage(.english, state: &state)
            return .merge(cancelHomeEffects(), .cancel(id: "RootFeature.fetchCurrentUser"))

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
                try? userDefaultsClient.save(AppLanguage.korean.apiCode, for: .appLanguage)
            }
            if let language, language != state.appLanguage {
                try? userDefaultsClient.save(language.apiCode, for: .appLanguage)
                let cancellation = resetMainContent(language: language, userProfile: user, selectedTab: state.selectedTab, state: &state)
                return .concatenate(cancellation, .merge(.send(.home(.onAppear)), .send(.more(.onAppear))))
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
            guard state.login.isRequiredTermsAgreed, let authInfo = state.login.authInfo else { return .none }
            let language = defaultLanguage(for: userType)
            try? userDefaultsClient.save(language.apiCode, for: .appLanguage)
            try? userDefaultsClient.save(userType.rawValue, for: .pendingOnboardingUserType)
            applyAppLanguage(language, state: &state)
            state.authInfo = authInfo
            state.onboarding = OnboardingFeature.State(userType: userType, appLanguage: language, socialName: authInfo.name)
            return .none

        case let .onboarding(.delegate(.completed(auth))):
            let keychainClient = keychainClient
            return .run { send in
                try keychainClient.save(auth, for: .auth)
                await send(.saveAuthResponse(.success(auth)))
            } catch: { error, send in
                await send(.saveAuthResponse(.failure(error)))
            }

        case let .saveAuthResponse(.success(auth)):
            userDefaultsClient.delete(for: .pendingOnboardingUserType)
            userDefaultsClient.delete(for: .requiresAuthCleanup)
            state.authInfo = auth
            let language = defaultLanguage(for: state.onboarding.userType)
            applyAppLanguage(language, state: &state)
            let updateProfileUseCase = updateProfileUseCase
            return .run { send in
                do {
                    let profile = try await updateProfileUseCase.execute(UserProfileUpdate(lang: language.apiCode))
                    await send(.onboardingLanguageUpdateResponse(language, .success(profile)))
                } catch {
                    await send(.onboardingLanguageUpdateResponse(language, .failure(error)))
                }
            }

        case let .onboardingLanguageUpdateResponse(language, .success(userProfile)):
            try? userDefaultsClient.save(language.apiCode, for: .appLanguage)
            state.isAuthenticationFlowPresented = false
            let cancellation = resetMainContent(language: language, userProfile: userProfile, selectedTab: state.selectedTab, state: &state)
            return .concatenate(cancellation, .merge(.send(.home(.onAppear)), .send(.more(.onAppear))))

        case .onboardingLanguageUpdateResponse(_, .failure):
            state.isAuthenticationFlowPresented = false
            return fetchCurrentUserIfNeeded(state: &state)

        default:
            return .none
        }
    }
}
