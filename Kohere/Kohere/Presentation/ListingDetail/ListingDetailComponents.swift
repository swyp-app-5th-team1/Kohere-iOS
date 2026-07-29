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
                Image("chevron_right_16")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.labelAlternative)
            }
        }
    }
}

struct ListingDetailRoomOfferCard: View {
    let offer: ListingRoomOfferModel

    @State private var isImageLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()

            Text(offer.name)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.common0)
                .lineLimit(1)
                .padding(.bottom, 4)

            Text(offer.pricingText)
                .kohereTextStyle(.body3Regular)
                .foregroundStyle(.common0)
                .lineLimit(1)

            HStack(spacing: 4) {
                ForEach(offer.tags, id: \.self) { tag in
                    Text(tag)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral5)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(4)
                        .frame(height: 22)
                        .background {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(isImageLoaded ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.backgroundTransparentAlternative))

                            if isImageLoaded {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(.backgroundTransparentAlternative)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 13)
        .frame(width: 285, height: 160, alignment: .bottomLeading)
        .background {
            KohereRemoteImageView(
                urlString: displayedImageURL,
                onImageLoaded: { isImageLoaded = true },
                placeholder: { Color.neutral20 }
            )
                .frame(width: 285, height: 160)
                .clipped()
                .overlay {
                    if isImageLoaded {
                        roomOfferGradient
                    } else {
                        fallbackRoomOfferGradient
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: displayedImageURL) {
            isImageLoaded = false
        }
    }

    private var displayedImageURL: String? {
        offer.imageURLs.first
    }

    private var roomOfferGradient: some View {
        roomOfferGradient(startColor: .common100.opacity(0.4))
    }

    private var fallbackRoomOfferGradient: some View {
        roomOfferGradient(startColor: .neutral80.opacity(0.3))
    }

    private func roomOfferGradient(startColor: Color) -> some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: startColor, location: 0.31762),
                Gradient.Stop(color: .common0.opacity(0), location: 0.87658)
            ],
            startPoint: UnitPoint(x: 0, y: 0.634),
            endPoint: UnitPoint(x: 1, y: 0.366)
        )
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

struct ListingDetailPropertySection: View {
    let title: String
    let rows: [ListingDetailInfoRowModel]
    let featuresTitle: String
    let features: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.common100)

            ForEach(rows) { row in
                ListingDetailInfoRow(
                    row: row,
                    showsDivider: row.id != rows.last?.id || !features.isEmpty
                )
            }

            if !features.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    Text(featuresTitle)
                        .kohereTextStyle(.body2Regular)
                        .foregroundStyle(.common100)
                        .frame(width: 110, alignment: .leading)

                    MapFilterFlowLayout(spacing: 4, rowSpacing: 4) {
                        ForEach(features, id: \.self) { feature in
                            Text(feature)
                                .kohereTextStyle(.caption2Regular)
                                .foregroundStyle(.labelNeutral)
                                .padding(4)
                                .frame(minHeight: 22)
                                .background(.fillAlternative)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 16)
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
                .kohereTextStyle(.body2Regular)
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
    let onMapPreviewTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ListingDetailSectionHeader(
                title: locationInfo.sectionTitle,
                count: nil,
                showsChevron: false
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

            ListingDetailMapPreview(
                coordinate: locationInfo.coordinate,
                onTap: onMapPreviewTapped
            )

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

struct ListingDetailReviewSection: View {
    let title: String
    let reviewCount: Int
    let emptyMessage: String
    let promptMessage: String

    var body: some View {
        VStack(spacing: 16) {
            ListingDetailSectionHeader(
                title: title,
                count: reviewCount,
                showsChevron: false
            )

            Text(
                reviewCount == 0
                    ? emptyMessage
                    : promptMessage
            )
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelAlternative)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.common0)
    }
}
