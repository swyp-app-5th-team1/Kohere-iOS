//
//  MoreView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MoreView: View {
    let store: StoreOf<MoreFeature>

    var body: some View {
        PlaceholderTabView(title: "더보기")
    }
}

#Preview {
    MoreView(
        store: Store(initialState: MoreFeature.State()) {
            MoreFeature()
        }
    )
}
