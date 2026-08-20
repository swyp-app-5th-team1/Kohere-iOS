//
//  ChatBotBubbleView.swift
//  Kohere
//
//  Created by soomin on 6/26/26.
//

import SwiftUI

struct ChatBotBubbleView: View {
    
    // MARK: - Properties
    
    let text: String
    let isFirstBubble: Bool
    
    // MARK: - Body
    
    var body: some View {
        Text(text)
            .kohereTextStyle(.label2Semibold)
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: isFirstBubble ? 0 : 12,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12
                )
                .fill(.common0)
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: isFirstBubble ? 0 : 12,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12
                )
                .stroke(.lineNeutral, lineWidth: 1)
            )
    }
}
