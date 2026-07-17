//
//  TermsDetailView.swift
//  Kohere
//
//  Created by Codex on 6/21/26.
//

import Foundation
import SwiftUI

enum TermsDetailKind: String, Equatable, Identifiable {
    case service
    case privacy
    case marketing
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .service:
            String(localized: "login.terms.service.title")
        case .privacy:
            String(localized: "login.terms.privacy.title")
        case .marketing:
            String(localized: "login.terms.marketing.title")
        }
    }

    var url: URL {
        switch self {
        case .service:
            URL(string: "https://jewel-humor-b3e.notion.site/39777dadb98580ad9a47eda58626c047?source=copy_link")!
        case .privacy:
            URL(string: "https://jewel-humor-b3e.notion.site/39777dadb9858039b2aedef03251cdf4?source=copy_link")!
        case .marketing:
            URL(string: "https://jewel-humor-b3e.notion.site/39077dadb985802ba1a8ffb0472238e4?source=copy_link")!
        }
    }
}

struct TermsDetailView: View {
    
    // MARK: - Properties
    
    let kind: TermsDetailKind
    let onBackTapped: () -> Void
    let onAgreeTapped: () -> Void
    @State private var isLoading = true
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton(onBackTapped),
                center: .text(kind.title),
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
                    url: kind.url,
                    onLoadingStarted: { isLoading = true },
                    onLoadingFinished: { isLoading = false }
                )

                if isLoading {
                    ProgressView()
                        .tint(.primary50)
                }
            }

            agreeButtonArea
        }
        .background {
            Color.backgroundNormalNormal
                .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var agreeButtonArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.lineNormal)
                .frame(height: 1)

            Button {
                onAgreeTapped()
            } label: {
                Text("common.agree")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundColor(.staticWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.primaryNormal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(.staticWhite)
    }
}
