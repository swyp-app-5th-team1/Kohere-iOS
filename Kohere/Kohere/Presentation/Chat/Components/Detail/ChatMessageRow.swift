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
    let onBookingCardTapped: () -> Void

    private var isMine: Bool { message.sender == participantRole }

    // MARK: - Body

    @ViewBuilder var body: some View {
        if let bookingCard = message.bookingCard {
            VStack(spacing: 12) {
                HStack {
                    if participantRole == .tenant { Spacer(minLength: 48) }
                    MoveInApplicationCardView(item: bookingCard,
                                              mode: participantRole == .landlord ? .landlord : .tenant)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onBookingCardTapped)
                    if participantRole == .landlord { Spacer(minLength: 48) }
                }

                if participantRole == .tenant {
                    applicationSentMessage
                }
            }
        } else if isMine {
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

    private var applicationSentMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)
                .background(.common0)
                .clipShape(Circle())
                .overlay(Circle().stroke(.lineNeutral, lineWidth: 1))

            Text(.chatApplicationSentTitle)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.staticBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.statusBlue5)
                .clipShape(applicationMessageShape)
                .overlay(applicationMessageShape.stroke(.lineNeutral, lineWidth: 1))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var applicationMessageShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12,
                               bottomTrailingRadius: 12, topTrailingRadius: 12)
    }
}
