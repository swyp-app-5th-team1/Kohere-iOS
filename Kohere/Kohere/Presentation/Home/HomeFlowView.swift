//
//  HomeFlowView.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeFlowView: View {
    
    // MARK: - Property
    
    @Bindable var store: StoreOf<HomeFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \HomeFeature.State.path,
                action: \.path
            )
        ) {
            HomeView(store: store)
        } destination: { store in
            Group {
                switch store.case {
                case let .savedListings(savedListingsStore):
                    SavedListingsView(store: savedListingsStore)
                        .navigationBarHidden(true)
                    
                case let .recentlyViewedList(recentlyViewedStore):
                    RecentlyViewedListingsView(store: recentlyViewedStore)
                        .navigationBarHidden(true)
                    
                case let .notifications(notificationsStore):
                    NotificationsView(store: notificationsStore)
                        .navigationBarHidden(true)
                    
                case let .chatBot(chatBotStore):
                    ChatBotView(store: chatBotStore)
                        .navigationBarHidden(true)

                case let .livingGuideDetail(livingGuideDetailStore):
                    LivingGuideDetailView(store: livingGuideDetailStore)
                        .navigationBarHidden(true)

                case let .search(searchStore):
                    SearchView(store: searchStore)
                        .navigationBarHidden(true)
                }
            }
        }
        .toolbar(store.path.isEmpty ? .visible : .hidden, for: .tabBar)
    }
}
