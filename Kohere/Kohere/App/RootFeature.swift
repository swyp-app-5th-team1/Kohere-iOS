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
    
    @ObservableState
    struct State: Equatable {
        var authInfo: Auth?
        var isAuthLoading = true
        var login = LoginFeature.State()
        var onboarding = OnboardingFeature.State()
        var selectedTab: AppTab = .home
        var home = HomeFeature.State()
        var community = CommunityFeature.State()
        var map = MapFeature.State()
        var chat = ChatFeature.State()
        var more = MoreFeature.State()
    }
    
    enum Action {
        case onAppear
        case storedAuthLoaded(Auth?)
        case authSessionExpired
        case login(LoginFeature.Action)
        case saveAuthResponse(Result<Auth, Error>)
        case onboarding(OnboardingFeature.Action)
        case selectedTabChanged(AppTab)
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
                var effects: [Effect<Action>] = [
                    .run { send in
                        for await _ in NotificationCenter.default.notifications(named: .authSessionExpired) {
                            await send(.authSessionExpired)
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

                            if !hasLaunchedBefore {
                                try keychainClient.delete(for: .auth)
                                try userDefaultsClient.save(true, for: .hasLaunchedBefore)
                            }

                            let auth = try keychainClient.load(for: .auth)
                            await send(.storedAuthLoaded(auth))
                        } catch: { _, send in
                            await send(.storedAuthLoaded(nil))
                        }
                    )
                }
                
                return .merge(effects)
                
            case let .storedAuthLoaded(auth):
                state.authInfo = auth
                state.isAuthLoading = false
                return .none

            case .authSessionExpired:
                state = State(isAuthLoading: false)
                return .none

            case let .login(.loginSuccess(auth)):
                guard !auth.onboardingRequired else { return .none }
                state.authInfo = auth
                return .none
                
            case let .login(.userTypeSelected(userType)):
                guard state.login.isRequiredTermsAgreed,
                      let authInfo = state.login.authInfo else { return .none }
                state.authInfo = authInfo
                state.onboarding = OnboardingFeature.State(userType: userType)
                return .none
                
            case .onboarding(.onboardingCompleted):
                guard let authInfo = state.authInfo else { return .none }
                let updatedAuthInfo = Auth(
                    onboardingRequired: false,
                    status: authInfo.status,
                    tokenType: authInfo.tokenType,
                    accessToken: authInfo.accessToken,
                    refreshToken: authInfo.refreshToken,
                    expiresIn: authInfo.expiresIn
                )
                let keychainClient = keychainClient
                
                return .run { send in
                    try keychainClient.save(updatedAuthInfo, for: .auth)
                    await send(.saveAuthResponse(.success(updatedAuthInfo)))
                } catch: { error, send in
                    await send(.saveAuthResponse(.failure(error)))
                }
            
            case let .saveAuthResponse(.success(updatedAuthInfo)):
                state.authInfo = updatedAuthInfo
                return .none

            case .saveAuthResponse(.failure):
                return .none
                
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
                
            case .login, .onboarding, .home, .community, .map, .chat, .more:
                return .none
            }
        }
    }
}
