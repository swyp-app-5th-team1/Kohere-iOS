//
//  RootView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    
    var body: some View {
        ZStack {
            Color.backgroundNormalNormal
                .ignoresSafeArea()
            
            if store.isAuthLoading {
                // TODO: 키체인 값을 읽어오는 동안 보여줄 화면
            } else if store.authInfo == nil {
                LoginView(
                    store: store.scope(
                        state: \RootFeature.State.login,
                        action: \.login
                    )
                )
            } else if store.authInfo?.onboardingRequired == true {
                OnboardingView(
                    store: store.scope(
                        state: \RootFeature.State.onboarding,
                        action: \.onboarding
                    )
                )
            } else {
                tabView
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private var tabView: some View {
        TabView(selection: $store.selectedTab.sending(\.selectedTabChanged)) {
            HomeFlowView(
                store: store.scope(
                    state: \RootFeature.State.home,
                    action: \.home
                )
            )
            .tabItem {
                tabIcon(.home)
            }
            .tag(AppTab.home)
            
            MapFlowView(
                store: store.scope(
                    state: \RootFeature.State.map,
                    action: \.map
                )
            )
            .tabItem {
                tabIcon(.map)
            }
            .tag(AppTab.map)
            
            ChatFlowView(
                store: store.scope(
                    state: \RootFeature.State.chat,
                    action: \.chat
                )
            )
            .tabItem {
                tabIcon(.chat)
            }
            .tag(AppTab.chat)
            
            MoreFlowView(
                store: store.scope(
                    state: \RootFeature.State.more,
                    action: \.more
                )
            )
            .tabItem {
                tabIcon(.more)
            }
            .tag(AppTab.more)
        }
        .tint(.primary50)
    }
    
    private func tabIcon(_ tab: AppTab) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .accessibilityLabel(tab.accessibilityLabel)
    }
}
