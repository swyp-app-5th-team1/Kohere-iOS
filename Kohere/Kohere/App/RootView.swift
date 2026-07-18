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

            if let popup = store.popup {
                popupOverlay(popup)
            }
        }
        .environment(\.locale, store.appLanguage.locale)
        .animation(.easeInOut(duration: 0.2), value: store.popup)
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
        .id(store.appLanguage)
        .onAppear {
            store.send(.mainTabAppeared)
        }
    }

    private func popupOverlay(_ popup: AppPopup) -> some View {
        ZStack {
            Color.materialDimmer
                .ignoresSafeArea()

            popupContent(popup)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .zIndex(10)
    }

    @ViewBuilder
    private func popupContent(_ popup: AppPopup) -> some View {
        switch popup {
        case let .notice(notice):
            KohereNoticePopup(
                message: notice.message,
                confirmTitle: notice.confirmTitle
            ) {
                store.send(.popupNoticeConfirmButtonTapped)
            }

        case let .action(action):
            KohereActionPopup(
                message: action.message,
                primaryTitle: action.primaryTitle,
                secondaryTitle: action.secondaryTitle
            ) {
                store.send(.popupActionPrimaryButtonTapped)
            } onSecondaryTapped: {
                store.send(.popupActionSecondaryButtonTapped)
            }
        }
    }
    
    private func tabIcon(_ tab: AppTab) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .accessibilityLabel(tab.accessibilityLabel)
    }
}
