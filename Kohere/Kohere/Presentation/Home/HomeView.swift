//
//  HomeView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        PlaceholderTabView(title: "홈")
    }
}
