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
        } destination: { _ in
            EmptyView()
        }
    }
}
