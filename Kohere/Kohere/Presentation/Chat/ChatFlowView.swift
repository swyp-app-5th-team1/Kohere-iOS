//
//  ChatFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatFlowView: View {
    @Bindable var store: StoreOf<ChatFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \ChatFeature.State.path,
                action: \.path
            )
        ) {
            ChatView(store: store)
        } destination: { _ in
            EmptyView()
        }
    }
}
