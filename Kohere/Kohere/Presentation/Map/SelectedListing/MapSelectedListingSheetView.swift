//
//  MapSelectedListingSheetView.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import SwiftUI

struct MapSelectedListingSheetView: View {
    let title: String
    let item: ListingItemModel
    let onCardTapped: () -> Void
    let onLikeTapped: () -> Void
    let onCloseButtonTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 2)

            selectedListingCard
                .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.common0)
        .clipShape(sheetShape)
        .kohereElevation(.bottomSheet, shape: .topRoundedRectangle(cornerRadius: 26))
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var sheetShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 26,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 26,
            style: .continuous
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.coolNeutral75)
                .lineLimit(1)

            Spacer()

            Button {
                onLikeTapped()
            } label: {
                Image(item.isLiked ? .heartFill24 : .heart24)
                    .renderingMode(.template)
                    .foregroundStyle(item.isLiked ? .primary50 : .labelAlternative)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(item.isLiked ? "찜 해제" : "찜하기"))

            Button {
                onCloseButtonTapped()
            } label: {
                Image("close_24")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.labelAlternative)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .accessibilityLabel(Text("닫기"))
        }
    }

    private var selectedListingCard: some View {
        ListingCardView(
            item: item,
            showsLikeButton: false,
            onCardTapped: onCardTapped,
            onLikeTapped: onLikeTapped
        )
    }
}
