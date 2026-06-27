//
//  ChatBotMessageRow.swift
//  Kohere
//
//  Created by mandoo on 6/27/26.
//

import SwiftUI

struct BotMessageRow: View {
    
    // MARK: - Properties
    
    let text: String
    let isFirst: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack {
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
