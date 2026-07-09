//
//  KohereImageFallbackView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import SwiftUI

struct KohereImageFallbackView: View {
    let backgroundColor: Color
    let iconColor: Color
    let iconSize: CGFloat
    let accessibilityLabel: String

    init(
        backgroundColor: Color = .neutral5,
        iconColor: Color = .labelAssistive,
        iconSize: CGFloat = 24,
        accessibilityLabel: String = "이미지를 불러오지 못했습니다"
    ) {
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .overlay {
                Image(.image24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(iconColor)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
    }
}
