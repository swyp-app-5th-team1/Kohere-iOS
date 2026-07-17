//
//  ChatFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatFlowView: View {
    
    // MARK: - Property
    
    @Bindable var store: StoreOf<ChatFeature>
    
    // MARK: - Body

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \ChatFeature.State.path,
                action: \.path
            )
        ) {
            ChatView(store: store)
        } destination: { store in
            switch store.case {
            case let .chatDetail(detailStore):
                ChatDetailView(store: detailStore)
                    .navigationBarHidden(true)

            case let .chatBot(chatBotStore):
                ChatBotView(store: chatBotStore)
                    .navigationBarHidden(true)

            case let .listingDetail(listingDetailStore):
                ListingDetailView(store: listingDetailStore)
                    .navigationBarHidden(true)
            }
        }
        .toolbar(store.path.isEmpty ? .visible : .hidden, for: .tabBar)
    }
}
