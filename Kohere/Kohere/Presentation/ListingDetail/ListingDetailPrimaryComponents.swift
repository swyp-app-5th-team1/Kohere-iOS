//
//  ListingDetailPrimaryComponents.swift
//  Kohere
//
//  Created by Codex on 6/29/26.
//

import SwiftUI

struct ListingDetailOverviewSection: View {
    let overview: ListingDetailOverviewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            priceBlock
            listingMetaBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(overview.monthlyRentText)
                    .kohereTextStyle(.heading1Bold)
                    .foregroundStyle(.common100)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(overview.convertedMonthlyRentText)
                    .kohereTextStyle(.label1Medium)
                    .foregroundStyle(.labelNeutral)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 2) {
                Text(overview.depositText)
                Text("·")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.labelAlternative)
                Text(overview.maintenanceFeeText)
            }
            .kohereTextStyle(.label1Medium)
            .foregroundStyle(.labelNeutral)
        }
    }

    private var listingMetaBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(overview.transitText)
                .kohereTextStyle(.body3Regular)
                .foregroundStyle(.labelAlternative)

            HStack(spacing: 4) {
                Text(overview.typeTag)
                    .kohereTextStyle(.body3Regular)
                    .foregroundStyle(.labelNormal)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.fillAlternative)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(.lineAlternative, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text(overview.title)
                    .kohereTextStyle(.body3Regular)
                    .foregroundStyle(.labelNormal)
                    .lineLimit(1)

                Text("·")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.labelAlternative)

                HStack(spacing: 2) {
                    Image(.review16)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)

                    Text("\(overview.reviewCount)")
                }
                .kohereTextStyle(.body3Regular)
                .foregroundStyle(.statusInfo)
            }
        }
    }
}

struct ListingDetailBottomBar: View {
    let isLiked: Bool
    let showsLikeButton: Bool
    let isApplyEnabled: Bool
    let onLikeTap: () -> Void
    let onApplyTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if showsLikeButton {
                Button(action: onLikeTap) {
                    Image(isLiked ? "heart_fill_24" : "heart_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isLiked ? .primary50 : .labelAlternative)
                        .frame(width: 48, height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.lineNormal, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isLiked ? "찜 해제" : "찜하기")
                .accessibilityValue(isLiked ? "찜한 매물" : "찜하지 않은 매물")
            }

            Button(action: onApplyTap) {
                Text("신청하기")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.staticWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isApplyEnabled ? .primary50 : .primary10)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isApplyEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.common0)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
    }
}

struct ListingDetailApplicationPanel: View {
    let roomOffers: [ListingRoomOfferModel]
    let selectedRoomOfferID: String?
    let isRoomTypeSelectorPresented: Bool
    let validationMessage: String?
    let onRoomTypeSelectorTap: () -> Void
    let onRoomOfferTap: (String) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            sheetBody

            if isRoomTypeSelectorPresented {
                roomOfferList
                    .offset(y: -roomOfferListHeight + 28)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if let validationMessage {
                Text(validationMessage)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.common0)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(.labelAlternative.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .offset(y: 62)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: isRoomTypeSelectorPresented)
        .animation(.easeInOut(duration: 0.2), value: validationMessage)
    }

    private var selectedRoomOffer: ListingRoomOfferModel? {
        guard let selectedRoomOfferID else { return nil }
        return roomOffers.first { $0.id == selectedRoomOfferID }
    }

    private var visibleRoomOfferCount: CGFloat {
        CGFloat(min(roomOffers.count, 4))
    }

    private var roomOfferListHeight: CGFloat {
        visibleRoomOfferCount * 52
    }

    private var sheetBody: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.bottom, 10)

            roomTypeSelector
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(.common0)
        .clipShape(sheetShape)
        .kohereElevation(.bottomSheet, shape: .topRoundedRectangle(cornerRadius: 26))
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

    private var roomTypeSelector: some View {
        Button(action: onRoomTypeSelectorTap) {
            HStack(spacing: 12) {
                Text(selectedRoomOffer?.name ?? "방 유형")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(isRoomTypeSelectorPresented || selectedRoomOffer != nil ? .labelStrong : .labelNeutral)

                Spacer()

                Image(.chevronDown16)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.labelAlternative)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(.common0)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isRoomTypeSelectorPresented ? .primaryNormal : .lineNormal, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var roomOfferList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(roomOffers) { offer in
                    Button {
                        onRoomOfferTap(offer.id)
                    } label: {
                        HStack(spacing: 8) {
                            Text(offer.name)
                                .kohereTextStyle(.label2Semibold)
                                .foregroundStyle(.labelStrong)

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(offer.id == selectedRoomOfferID ? .primary5 : .backgroundNormalNormal)
                    }
                    .buttonStyle(.plain)

                    if offer.id != roomOffers.last?.id {
                        Rectangle()
                            .fill(.lineNormal)
                            .frame(height: 1)
                    }
                }
            }
        }
        .background(.backgroundNormalNormal)
        .frame(height: roomOfferListHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.primaryNormal, lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }
}
