//
//  KohereApp.swift
//  Kohere
//
//  Created by 송규섭 on 6/11/26.
//

import ComposableArchitecture
import GoogleSignIn
import SwiftUI

@main
struct KohereApp: App {
    init() {
        TabBarAppearanceConfigurator.configure()
    }
    
    // true: 바로 메인으로 진입 / false: 소셜 로그인 후 진입
    private let isDebugSkipLogin: Bool = false
    // true: 실제 로그인 토큰은 유지하고 온보딩 화면만 임시로 건너뜀
    private let isDebugSkipOnboarding: Bool = true
    
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: makeInitialState()) {
                    RootFeature()
                }
            )
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
    
    private func makeInitialState() -> RootFeature.State {
        if isDebugSkipLogin {
            // true: 바로 메인으로 진입 (가짜 토큰 주입)
            return RootFeature.State(
                authInfo: Auth(
                    onboardingRequired: false,
                    status: .active,
                    tokenType: "Bearer",
                    accessToken: "mock_access_token_for_debug",
                    refreshToken: "mock_refresh_token_for_debug",
                    expiresIn: 3600
                ),
                isAuthLoading: false,
                isOnboardingBypassedForDebug: isDebugSkipOnboarding,
                selectedTab: .home
            )
        } else {
            // false: 소셜 로그인 후 진입 (실제 로그인 흐름)
            return RootFeature.State(
                isOnboardingBypassedForDebug: isDebugSkipOnboarding
            )
        }
    }
}
