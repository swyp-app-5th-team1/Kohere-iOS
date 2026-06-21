//
//  HomeFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeFlowView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \HomeFeature.State.path,
                action: \.path
            )
        ) {
            HomeView(store: store)
        } destination: { _ in
            EmptyView()
        }
    }
}
