//
//  UserChatBubbleView.swift
//  Kohere
//
//  Created by soomin on 6/26/26.
//

import SwiftUI

struct UserChatBubbleView: View {
    
    // MARK: - Property
    
    let text: String
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(text)
                .kohereTextStyle(.label2Semibold)
                .foregroundColor(.primary30)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0
                    )
                    .fill(.primary5)
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0
                    )
                    .stroke(.primary10, lineWidth: 1)
                )
        }
    }
}
