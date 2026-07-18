//
//  CommunityView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    @Environment(\.locale)
    private var locale

    var body: some View {
        PlaceholderTabView(title: String(localized: "tab.community", locale: locale))
    }
}
