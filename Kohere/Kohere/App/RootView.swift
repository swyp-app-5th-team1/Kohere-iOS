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

            CommunityFlowView(
                store: store.scope(
                    state: \RootFeature.State.community,
                    action: \.community
                )
            )
                .tabItem {
                    tabIcon(.community)
                }
                .tag(AppTab.community)

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
        .tint(Color("primary50"))
    }

    private func tabIcon(_ tab: AppTab) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .accessibilityLabel(tab.accessibilityLabel)
    }
}
