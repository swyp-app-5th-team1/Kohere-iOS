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
    @Environment(\.locale)
    private var locale

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton { store.send(.backButtonTapped) },
                center: .text(String(localized: "more.support.announcements", locale: locale)),
                right: .none
            )

            KohereEmptyView(title: String(localized: "announcements.empty.title", locale: locale))
        }
        .background(.backgroundNormalNormal)
    }
}
