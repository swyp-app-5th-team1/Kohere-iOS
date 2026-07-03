//
//  PromoteRoomWebView.swift
//  Kohere
//
//  Created by Codex on 7/2/26.
//

import ComposableArchitecture
import SwiftUI
import WebKit

struct PromoteRoomWebView: View {
    let store: StoreOf<PromoteRoomWebFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) })
            )

            ZStack {
                WebPageView(
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

private struct WebPageView: UIViewRepresentable {
    let url: URL
    let onLoadingStarted: () -> Void
    let onLoadingFinished: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onLoadingStarted: () -> Void
        private let onLoadingFinished: () -> Void

        init(
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingStarted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingFinished()
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            onLoadingFinished()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            onLoadingFinished()
        }
    }
}
