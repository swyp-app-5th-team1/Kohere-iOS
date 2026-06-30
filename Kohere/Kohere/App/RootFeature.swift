//
//  RootFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

@Reducer
struct RootFeature {
    @Dependency(\.keychainClient)
    var keychainClient

    @ObservableState
    struct State: Equatable {
        var authInfo: Auth?
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
        case login(LoginFeature.Action)
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
                guard state.authInfo == nil else { return .none }

                return .run { send in
                    let auth = try await keychainClient.loadAuth()
                    await send(.storedAuthLoaded(auth))
                } catch: { _, _ in
                }

            case let .storedAuthLoaded(auth):
                state.authInfo = auth
                return .none
                
            case .login(.termsAgreementCompleted):
                guard let authInfo = state.login.authInfo else { return .none }
                state.authInfo = authInfo
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
                state.authInfo = updatedAuthInfo

                return .run { _ in
                    try await keychainClient.saveAuth(updatedAuthInfo)
                } catch: { _, _ in
                }
                
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
                
            case .login, .onboarding, .home, .community, .map, .chat, .more:
                return .none
            }
        }
    }
}
