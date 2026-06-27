//
//  MoreFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MoreFlowView: View {
    @Bindable var store: StoreOf<MoreFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \MoreFeature.State.path,
                action: \.path
            )
        ) {
            MoreView(store: store)
        } destination: { store in
            switch store.case {
            case let .profileEdit(profileEditStore):
                ProfileEditView(store: profileEditStore)
                    .navigationBarHidden(true)
            }
        }
    }
}
