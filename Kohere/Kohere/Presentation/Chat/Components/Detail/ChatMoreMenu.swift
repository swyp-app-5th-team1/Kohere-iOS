//
//  ChatMoreMenu.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import SwiftUI

struct ChatMoreMenu: View {
    
    // MARK: - Property

    let onAction: (ChatFeature.SwipeAction) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 15) {
            menuButton("chat.action.report", image: .megaphone24, action: .report)
            menuButton("chat.action.block", image: .circleBlock24, action: .block)
            menuButton("chat.action.delete", image: .trash24, action: .delete)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(.backgroundNormalNormal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.lineNormal, lineWidth: 1)
        )
    }

    // MARK: - Method

    private func menuButton(_ key: String, image: ImageResource, action: ChatFeature.SwipeAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: 6) {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text(String(localized: String.LocalizationValue(key)))
                    .kohereTextStyle(.body3Regular)
            }
            .foregroundStyle(.labelNormal)
        }
        .buttonStyle(.plain)
    }
}
