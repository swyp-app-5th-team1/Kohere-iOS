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
    let showsSenderProfile: Bool
    let onListingCardTapped: (String) -> Void
    let onRetryTapped: (UUID) -> Void
    let onDeleteTapped: (UUID) -> Void

    private var isMine: Bool { message.sender == participantRole }
    private var isUserSubmittedCard: Bool { participantRole == .tenant }

    // MARK: - Body

    @ViewBuilder var body: some View {
        if let inquiryCard = message.inquiryCard {
            if participantRole == .landlord {
                VStack(spacing: 8) {
                    inquiryReceivedMessage
                    inquiryCardView(inquiryCard)
                }
            } else {
                inquiryCardView(inquiryCard)
            }
        } else if message.type == .inquiryCard {
            Text("chat.inquiryCard.unavailable")
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.neutral40)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        } else if let bookingCard = message.bookingCard {
            if participantRole == .landlord {
                VStack(spacing: 8) {
                    applicationReceivedMessage
                    bookingCardView(bookingCard)
                }
            } else {
                VStack(spacing: 12) {
                    bookingCardView(bookingCard)
                    applicationSentMessage
                }
            }
        } else if isMine {
            HStack(alignment: .bottom, spacing: message.deliveryStatus == .failed ? 8 : 4) {
                Spacer(minLength: 48)

                if message.deliveryStatus == .failed,
                   let clientMessageID = message.clientMessageID {
                    failedMessageActions(clientMessageID)
                } else {
                    time
                }
                bubble
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Image(.chatProfile)
                    .renderingMode(.original)
                    .opacity(showsSenderProfile ? 1 : 0)
                    .accessibilityHidden(!showsSenderProfile)

                HStack(alignment: .bottom, spacing: 4) {
                    bubble
                    time
                }

                Spacer(minLength: 48)
            }
        }
    }
    
    // MARK: - SubView

    private func listingCardAlignment<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUserSubmittedCard {
                Spacer(minLength: 0)

                time
                    .padding(.bottom, 2)
                content()
            } else {
                Color.clear
                    .frame(width: 32, height: 1)

                content()
                time
                    .padding(.bottom, 2)
                Spacer(minLength: 0)
            }
        }
    }

    private func bookingCardView(_ bookingCard: ChatRoomModel) -> some View {
        listingCardAlignment {
            MoveInApplicationCardView(item: bookingCard,
                                      mode: participantRole == .landlord ? .landlord : .tenant)
                .contentShape(Rectangle())
                .onTapGesture {
                    onListingCardTapped(bookingCard.listingID)
                }
        }
    }

    private func inquiryCardView(_ inquiryCard: ChatInquiryCard) -> some View {
        listingCardAlignment {
            ChatInquiryListingCard(item: inquiryCard) {
                onListingCardTapped(inquiryCard.listingID)
            }
        }
    }
    
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

    private func failedMessageActions(_ clientMessageID: UUID) -> some View {
        HStack(spacing: 0) {
            Button {
                onRetryTapped(clientMessageID)
            } label: {
                Image(.reset16)
                    .renderingMode(.template)
                    .scaleEffect(x: -1, y: 1)
                    .foregroundStyle(.labelStrong)
                    .frame(width: 16, height: 16)
                    .frame(width: 25, height: 25)
            }

            Rectangle()
                .fill(.lineNeutral)
                .frame(width: 1, height: 25)

            Button {
                onDeleteTapped(clientMessageID)
            } label: {
                Image(.close16)
                    .renderingMode(.template)
                    .foregroundStyle(.statusRed50)
                    .frame(width: 16, height: 16)
                    .frame(width: 25, height: 25)
            }
        }
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.lineNeutral, lineWidth: 1)
        }
        .buttonStyle(.plain)
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

            HStack(alignment: .bottom, spacing: 4) {
                Text(.chatApplicationSentTitle)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.staticBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.statusBlue5)
                    .clipShape(applicationMessageShape)
                    .overlay(applicationMessageShape.stroke(.lineNeutral, lineWidth: 1))

                time
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var applicationReceivedMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)
                .background(.common0)
                .clipShape(Circle())
                .overlay(Circle().stroke(.lineNeutral, lineWidth: 1))

            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.chatApplicationReceivedTitle)
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.staticBlack)

                    Text(.chatApplicationReceivedMessage)
                        .kohereTextStyle(.body2Regular)
                        .foregroundStyle(.staticBlack)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: 270, alignment: .leading)
                .background(.backgroundNormalAlternative)
                .clipShape(applicationMessageShape)
                .overlay(applicationMessageShape.stroke(.lineNeutral, lineWidth: 1))

                time
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inquiryReceivedMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)
                .background(.common0)
                .clipShape(Circle())
                .overlay(Circle().stroke(.lineNeutral, lineWidth: 1))

            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.chatInquiryReceivedTitle)
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.staticBlack)

                    Text(.chatInquiryReceivedMessage)
                        .kohereTextStyle(.body2Regular)
                        .foregroundStyle(.staticBlack)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: 270, alignment: .leading)
                .background(.backgroundNormalAlternative)
                .clipShape(applicationMessageShape)
                .overlay(applicationMessageShape.stroke(.lineNeutral, lineWidth: 1))

                time
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var applicationMessageShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12,
                               bottomTrailingRadius: 12, topTrailingRadius: 12)
    }
}
