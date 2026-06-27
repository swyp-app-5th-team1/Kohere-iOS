//
//  ListingDetailComponents.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct ListingDetailSectionHeader: View {
    let title: String
    let count: Int?
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.common100)

            if let count {
                Text("\(count)")
                    .kohereTextStyle(.heading3Semibold)
                    .foregroundStyle(.labelNeutral)
            }

            Spacer()

            if showsChevron {
                Image("chevron_right_24")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.labelAlternative)
            }
        }
    }
}

struct ListingDetailRoomOfferCard: View {
    let offer: ListingRoomOfferModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()

            Text(offer.name)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.common0)
                .lineLimit(1)

            Text(offer.pricingText)
                .kohereTextStyle(.body3Regular)
                .foregroundStyle(.common0)
                .lineLimit(1)

            MapFilterFlowLayout(spacing: 4, rowSpacing: 4) {
                ForEach(offer.tags, id: \.self) { tag in
                    Text(tag)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral5)
                        .padding(4)
                        .frame(height: 22)
                        .background(.backgroundTransparentAlternative)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 13)
        .frame(width: 285, height: 160, alignment: .bottomLeading)
        .background {
            Image(.roomPlaceholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 285, height: 160)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .common100.opacity(0.55), location: 0),
                            Gradient.Stop(color: .common100.opacity(0.18), location: 0.52),
                            Gradient.Stop(color: .clear, location: 1)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ListingDetailInfoSection: View {
    let title: String
    let rows: [ListingDetailInfoRowModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.common100)
                .padding(.bottom, 8)

            ForEach(rows) { row in
                ListingDetailInfoRow(row: row, showsDivider: row.id != rows.last?.id)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(.common0)
    }
}

struct ListingDetailInfoRow: View {
    let row: ListingDetailInfoRowModel
    let showsDivider: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(row.title)
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.common100)
                .frame(width: 110, alignment: .leading)

            Text(row.value)
                .kohereTextStyle(.body3Regular)
                .foregroundStyle(.labelNeutral)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(.lineNeutral)
                    .frame(height: 1)
            }
        }
    }
}

struct ListingDetailLocationSection: View {
    let locationInfo: ListingLocationInfoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ListingDetailSectionHeader(
                title: locationInfo.sectionTitle,
                count: nil,
                showsChevron: true
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(locationInfo.addressText)
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.labelNeutral)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(locationInfo.transits) { transit in
                            ListingDetailTransitView(transit: transit)
                        }
                    }
                }
            }

            ListingDetailMapPreview()

            ListingDetailInfoRow(
                row: ListingDetailInfoRowModel(
                    id: "nearby",
                    title: locationInfo.nearbyPlacesTitle,
                    value: locationInfo.nearbyPlacesText
                ),
                showsDivider: false
            )
            .padding(.vertical, 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.common0)
    }
}

struct ListingDetailTransitView: View {
    let transit: ListingTransitInfoModel

    var body: some View {
        HStack(spacing: 4) {
            Text(transit.lineText)
                .kohereTextStyle(.caption2Regular)
                .foregroundStyle(.common0)
                .frame(width: 16, height: 16)
                .background(Color(transit.lineColorName))
                .clipShape(Circle())

            Text(transit.description)
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.labelNeutral)
                .lineLimit(1)
        }
    }
}

struct ListingDetailMapPreview: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.neutral5)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                ZStack {
                    VStack(spacing: 18) {
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                        Rectangle().fill(.common0.opacity(0.8)).frame(height: 8)
                    }
                    .rotationEffect(.degrees(-12))

                    VStack(spacing: 24) {
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                        Rectangle().fill(.lineNeutral).frame(height: 1)
                    }

                    Image("locationMarker")
                        .resizable()
                        .frame(width: 36, height: 36)
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ListingDetailReviewSection: View {
    let reviewCount: Int

    var body: some View {
        VStack(spacing: 16) {
            ListingDetailSectionHeader(
                title: "리뷰",
                count: reviewCount,
                showsChevron: true
            )

            Text(reviewCount == 0 ? "등록된 리뷰가 없어요" : "리뷰를 확인해보세요")
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelAlternative)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.common0)
    }
}
