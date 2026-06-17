//
//  CommunityFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct CommunityFlowView: View {
    @Bindable var store: StoreOf<CommunityFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \CommunityFeature.State.path,
                action: \.path
            )
        ) {
            CommunityView(store: store)
        } destination: { _ in
            EmptyView()
        }
    }
}
