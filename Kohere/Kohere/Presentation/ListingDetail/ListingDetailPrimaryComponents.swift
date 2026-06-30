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
    let onLikeTap: () -> Void
    let onContactTap: () -> Void
    let onApplyTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
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

            Button(action: onContactTap) {
                Text("문의 하기")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.primary50)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.primary5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.lineAlternative, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onApplyTap) {
                Text("신청 하기")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.common0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.primary50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
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
