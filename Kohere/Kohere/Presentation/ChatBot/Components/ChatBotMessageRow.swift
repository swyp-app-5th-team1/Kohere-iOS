//
//  ChatBotMessageRow.swift
//  Kohere
//
//  Created by soomin on 6/27/26.
//

import SwiftUI

struct BotMessageRow: View {
    
    // MARK: - Properties
    
    let text: String
    let isFirst: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isFirst {
                Circle()
                    .stroke(.lineNeutral, lineWidth: 1)
                    .background(Circle().fill(.staticWhite))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(.smallLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
            } else {
                Color.clear
                    .frame(width: 32, height: 32)
            }
            
            ChatBotBubbleView(text: text, isFirstBubble: isFirst)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct UserMessageRow: View {
    
    // MARK: - Property
    
    let text: String
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Spacer()
            UserChatBubbleView(text: text)
        }
        .padding(.horizontal, 20)
    }
}
