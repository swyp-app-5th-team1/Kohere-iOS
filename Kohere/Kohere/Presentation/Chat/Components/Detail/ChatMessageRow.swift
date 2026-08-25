//
//  ChatMessageRow.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import SwiftUI

struct ChatMessageRow: View {
    
    // MARK: - Properties

    let message: ChatMessage
    let participantRole: ChatRoomRole

    private var isMine: Bool { message.sender == participantRole }

    // MARK: - Body

    @ViewBuilder var body: some View {
        if isMine {
            HStack(alignment: .bottom, spacing: 4) {
                Spacer(minLength: 48)

                time
                bubble
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Image(.chatProfile)
                    .renderingMode(.original)

                HStack(alignment: .bottom, spacing: 4) {
                    bubble
                    time
                }

                Spacer(minLength: 48)
            }
        }
    }
    
    // MARK: - SubView
    
    private var bubble: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(message.originalText)
                .kohereTextStyle(isMine ? .label2Semibold : (message.translatedText == nil ? .label2Semibold : .label2Medium))
                .foregroundStyle(isMine ? .primary30 : (message.translatedText == nil ? .coolNeutral80 : .coolNeutral20))

            if !isMine, let translatedText = message.translatedText {
                Text(translatedText)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.coolNeutral80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isMine ? .primary5 : .common0)
        .clipShape(bubbleShape)
        .overlay(
            bubbleShape
                .stroke(isMine ? .primary10 : .lineNeutral, lineWidth: 1)
        )
    }

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: isMine ? 12 : 0, bottomLeadingRadius: 12,
                               bottomTrailingRadius: 12, topTrailingRadius: isMine ? 0 : 12)
    }

    private var time: some View {
        Text(message.timeText)
            .kohereTextStyle(.caption2Regular)
            .foregroundStyle(.neutral20)
    }
}
