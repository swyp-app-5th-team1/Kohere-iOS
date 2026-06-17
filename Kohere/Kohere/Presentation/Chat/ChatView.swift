//
//  ChatView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatView: View {
    let store: StoreOf<ChatFeature>

    var body: some View {
        PlaceholderTabView(title: "채팅")
    }
}
