//
//  ChatDetailNavigationBar.swift
//  Kohere
//
//  Created by soomin on 8/22/26.
//

import SwiftUI

struct ChatDetailNavigationBar: View {
    
    // MARK: - Properties

    let title: String
    let subtitle: String
    let onBackTapped: () -> Void
    let onMoreTapped: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)

                Text(subtitle)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundStyle(.neutral50)
            }
            .lineLimit(1)

            HStack(spacing: 0) {
                Button(action: onBackTapped) {
                    Image(.chevronLeft24)
                        .renderingMode(.template)
                        .foregroundStyle(.labelNormal)
                        .frame(width: 24, height: 24)
                }

                Spacer()

                Button(action: onMoreTapped) {
                    Image(.moreVertical24)
                        .renderingMode(.template)
                        .foregroundStyle(.labelNormal)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 56)
        .background(.backgroundNormalNormal)
    }
}
