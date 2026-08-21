//
//  ChatTenantInitialContent.swift
//  Kohere
//
//  Created by soomin on 8/22/26.
//

import SwiftUI

struct ChatTenantInitialContent: View {
    
    // MARK: - Properties

    let item: ChatRoomModel
    let hasSubmittedApplication: Bool
    let onDetailsTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                Spacer()

                if !item.timeText.isEmpty {
                    Text(item.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral20)
                }

                if hasSubmittedApplication {
                    MoveInApplicationCardView(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onDetailsTapped)
                } else {
                    ChatInquiryListingCard(item: item, action: onDetailsTapped)
                        .frame(width: 280)
                }
            }
            .padding(.horizontal, 20)

            if hasSubmittedApplication {
                applicationSentMessage
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - SubView

    private var applicationSentMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)
                .background(.common0)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.lineNeutral, lineWidth: 1)
                )

            Text(.chatApplicationSentTitle)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.staticBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.statusBlue5)
                .clipShape(messageShape)
                .overlay(
                    messageShape
                        .stroke(.lineNeutral, lineWidth: 1)
                )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }

    private var messageShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12,
                               bottomTrailingRadius: 12, topTrailingRadius: 12)
    }
}
