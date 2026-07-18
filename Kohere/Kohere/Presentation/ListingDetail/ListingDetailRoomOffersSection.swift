//
//  ListingDetailRoomOffersSection.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailRoomOffersSection: View {
    let title: String
    let roomOffers: [ListingRoomOfferModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ListingDetailSectionHeader(
                title: title,
                count: roomOffers.count,
                showsChevron: false
            )
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(roomOffers) { offer in
                        ListingDetailRoomOfferCard(offer: offer)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(.common0)
    }
}
