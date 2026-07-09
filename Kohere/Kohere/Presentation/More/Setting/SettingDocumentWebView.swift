//
//  SettingDocumentWebView.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture
import SwiftUI

struct SettingDocumentWebView: View {
    let store: StoreOf<SettingDocumentWebFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) }),
                center: .none,
                backgroundColor: .common0,
                height: 48
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.lineNeutral)
                    .frame(height: 1)
            }

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
