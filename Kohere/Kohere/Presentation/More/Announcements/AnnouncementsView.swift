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
                center: .text(AppLanguage(locale: locale).localized(.moreSupportAnnouncements)),
                right: .none
            )

            KohereEmptyView(
                title: AppLanguage(locale: locale).localized(.announcementsEmptyTitle)
            )
        }
        .background(.backgroundNormalNormal)
        .interactivePopGestureEnabled()
    }
}
