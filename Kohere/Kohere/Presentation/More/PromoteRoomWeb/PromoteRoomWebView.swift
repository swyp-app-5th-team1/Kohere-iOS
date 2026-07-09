//
//  PromoteRoomWebView.swift
//  Kohere
//
//  Created by Codex on 7/2/26.
//

import ComposableArchitecture
import SwiftUI

struct PromoteRoomWebView: View {
    let store: StoreOf<PromoteRoomWebFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) })
            )

            ZStack {
                KohereWebPageView(
                    url: store.url,
                    onLoadingStarted: { store.send(.loadingStarted) },
                    onLoadingFinished: { store.send(.loadingFinished) }
                )

                if store.isLoading {
                    ProgressView()
                        .tint(.primary50)
                }
            }
        }
        .background(.backgroundNormalNormal)
    }
}
