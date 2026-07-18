//
//  AnnouncementsView.swift
//  Kohere
//
//  Created by Codex on 7/18/26.
//

import ComposableArchitecture
import SwiftUI

struct AnnouncementsView: View {
    let store: StoreOf<AnnouncementsFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton { store.send(.backButtonTapped) },
                center: .text(String(localized: "more.support.announcements")),
                right: .none
            )

            KohereEmptyView(title: String(localized: "announcements.empty.title"))
        }
        .background(.backgroundNormalNormal)
    }
}
