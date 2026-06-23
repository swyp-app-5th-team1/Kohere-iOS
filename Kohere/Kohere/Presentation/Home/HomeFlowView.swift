//
//  HomeFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
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
            switch store.case {
            case let .savedListings(savedListingsStore):
                SavedListingsView(store: savedListingsStore)
                    .navigationBarHidden(true)
                
            case let .recentlyViewedList(recentlyViewedStore):
                RecentlyViewedListngsView(store: recentlyViewedStore)
                    .navigationBarHidden(true)
            
            case let .notifications(notificationsStore):
                NotificationsView(store: notificationsStore)
                    .navigationBarHidden(true)
            }
        }
    }
}
