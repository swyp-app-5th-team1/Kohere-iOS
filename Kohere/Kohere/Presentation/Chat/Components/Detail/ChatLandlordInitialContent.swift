//
//  ChatLandlordInitialContent.swift
//  Kohere
//
//  Created by soomin on 8/22/26.
//

import SwiftUI

struct ChatLandlordInitialContent: View {
    
    // MARK: - Property

    let item: ChatRoomModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                avatar
                requestMessage
                Spacer(minLength: 0)
            }

            HStack(alignment: .bottom, spacing: 8) {
                Color.clear
                    .frame(width: 32, height: 1)

                MoveInApplicationCardView(
                    item: item,
                    mode: .landlord
                )

                if !item.timeText.isEmpty {
                    Text(item.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral20)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - SubView

    private var avatar: some View {
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
    }

    private var requestMessage: some View {
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
        .clipShape(messageShape)
        .overlay(
            messageShape
                .stroke(.lineNeutral, lineWidth: 1)
        )
    }

    private var messageShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12,
                               bottomTrailingRadius: 12, topTrailingRadius: 12)
    }
}
