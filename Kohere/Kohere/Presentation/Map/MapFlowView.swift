//
//  MapFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MapFlowView: View {
    @Bindable var store: StoreOf<MapFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \MapFeature.State.path,
                action: \.path
            )
        ) {
            MapView(store: store)
        } destination: { store in
            switch store.case {
            case let .listingDetail(listingDetailStore):
                ListingDetailView(store: listingDetailStore)
                    .navigationBarHidden(true)

            case let .listingApplication(listingApplicationStore):
                ListingApplicationView(store: listingApplicationStore)
                    .navigationBarHidden(true)

            case let .listingApplicationPrivacyWeb(privacyWebStore):
                ListingApplicationPrivacyWebView(store: privacyWebStore)
                    .navigationBarHidden(true)

            case let .chatBot(chatBotStore):
                ChatBotView(store: chatBotStore)
                    .navigationBarHidden(true)

            case let .search(searchStore):
                SearchView(store: searchStore)
                    .navigationBarHidden(true)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(store.path.isEmpty ? .visible : .hidden, for: .tabBar)
    }
}
