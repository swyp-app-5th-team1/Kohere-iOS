//
//  ChatInquiryListingCard.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import SwiftUI

struct ChatInquiryListingCard: View {
    
    // MARK: - Properties

    let item: ChatRoomModel
    let action: () -> Void

    @Environment(\.locale)
    private var locale

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            KohereRemoteImageView(urlString: item.thumbnailURL)
                .frame(height: 173)
                .clipped()

            VStack(alignment: .leading, spacing: 0) {
                Text(item.listingName)
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral70)
                    .padding(.bottom, 4)

                Text(item.location)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.coolNeutral30)

                if !cardFormatter.pricePerMonth.isEmpty {
                    Text(cardFormatter.pricePerMonth)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.coolNeutral30)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                Text("chat.detail.viewDetails")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.statusInfo)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.statusBlue5)
            }
            .buttonStyle(.plain)
        }
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.coolNeutral8, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 4)
    }
    
    // MARK: - SubView
    
    private var cardFormatter: ChatApplicationCardFormatter {
        ChatApplicationCardFormatter(item: item, language: AppLanguage(locale: locale))
    }
}
