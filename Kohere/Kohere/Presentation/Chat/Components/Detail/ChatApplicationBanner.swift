//
//  ChatApplicationBanner.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import SwiftUI

struct ChatApplicationBanner: View {
    
    // MARK: - Property

    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(.calendar24)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.statusBlue80)

                Text("chat.detail.applicationBanner")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.statusBlue80)

                Spacer()

                Image(.chevronRight24)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.statusBlue80)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(.statusBlue5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
