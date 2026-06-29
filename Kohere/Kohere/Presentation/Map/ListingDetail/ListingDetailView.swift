//
//  ListingDetailView.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import ComposableArchitecture
import SwiftUI

struct ListingDetailView: View {
    let store: StoreOf<ListingDetailFeature>
    @State private var topChromeProgress: CGFloat = 0
    @State private var verticalScrollOffset: CGFloat = 0
    @State private var fallbackScrollOffsetBaseline: CGFloat?
    @State private var showsPinnedTabs = false

    private let collapsedNavigationBarHeight: CGFloat = 100
    private let collapsedNavigationBarThreshold: CGFloat = 211
    private let sectionTabsPinOffset: CGFloat = 356

    var body: some View {
        ZStack(alignment: .top) {
            detailScrollView

            topChromeOverlay
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .background(.neutral5)
        .ignoresSafeArea(edges: .top)
    }

    private var detailScrollView: some View {
        Group {
            if #available(iOS 18.0, *) {
                baseScrollView
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, offset in
                        updateScrollPosition(offset)
                    }
            } else {
                baseScrollView
                    .onPreferenceChange(ListingDetailScrollOffsetPreferenceKey.self) { minY in
                        if fallbackScrollOffsetBaseline == nil {
                            fallbackScrollOffsetBaseline = minY
                        }

                        let offset = (fallbackScrollOffsetBaseline ?? minY) - minY
                        updateScrollPosition(offset)
                    }
            }
        }
    }

    private var baseScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                scrollOffsetReader

                VStack(spacing: 16) {
                    heroSection
                    tabsAndRoomOffersSection
                    ListingDetailInfoSection(title: "가격 정보", rows: store.detail.priceInfo)
                    ListingDetailInfoSection(title: "매물 정보", rows: store.detail.propertyInfo)
                    ListingDetailInfoSection(title: "건물 정보", rows: store.detail.buildingInfo)
                    ListingDetailInfoSection(title: "공용시설", rows: store.detail.facilityInfo)
                    ListingDetailLocationSection(locationInfo: store.detail.locationInfo)
                    ListingDetailReviewSection(reviewCount: store.detail.overview.reviewCount)
                }
                .padding(.bottom, 98)
            }
        }
    }

    private func updateScrollPosition(_ offset: CGFloat) {
        let normalizedOffset = max(offset, 0)
        verticalScrollOffset = normalizedOffset
        topChromeProgress = min(max(normalizedOffset / collapsedNavigationBarThreshold, 0), 1)
        updatePinnedTabs(for: normalizedOffset)
    }

    private func updatePinnedTabs(for offset: CGFloat) {
        showsPinnedTabs = offset >= sectionTabsPinOffset
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            heroImage
            overviewSection
        }
        .background(.common0)
    }

    private var heroImage: some View {
        Image(.roomPlaceholder)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 267)
            .clipped()
            .overlay {
                Color.common100.opacity(0.2)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(store.detail.overview.imageCountText)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundStyle(.common0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.backgroundTransparentAlternative)
                    .clipShape(Capsule())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
    }

    private var topChromeOverlay: some View {
        VStack(spacing: 0) {
            topNavigationBar

            if showsPinnedTabs {
                sectionTabs
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(2)
    }

    private var topNavigationBar: some View {
        HStack {
            topChromeButton(imageName: "chevron_left_24") {
                store.send(.backButtonTapped)
            }

            Spacer()

            topChromeButton(imageName: "share_ios_24") {
                store.send(.shareButtonTapped)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .frame(maxWidth: .infinity)
        .frame(height: collapsedNavigationBarHeight, alignment: .bottom)
        .background(.common0.opacity(topChromeProgress))
    }

    private func topChromeButton(imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.common0)
                    .opacity(1 - topChromeProgress)

                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.labelAlternative)
                    .opacity(topChromeProgress)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(store.detail.overview.monthlyRentText)
                        .kohereTextStyle(.heading1Bold)
                        .foregroundStyle(.common100)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(store.detail.overview.convertedMonthlyRentText)
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(.labelNeutral)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                HStack(spacing: 2) {
                    Text(store.detail.overview.depositText)
                    Text("·")
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.labelAlternative)
                    Text(store.detail.overview.maintenanceFeeText)
                }
                .kohereTextStyle(.label1Medium)
                .foregroundStyle(.labelNeutral)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.detail.overview.transitText)
                    .kohereTextStyle(.body3Regular)
                    .foregroundStyle(.labelAlternative)

                HStack(spacing: 4) {
                    Text(store.detail.overview.typeTag)
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

                    Text(store.detail.overview.title)
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

                        Text("\(store.detail.overview.reviewCount)")
                    }
                    .kohereTextStyle(.body3Regular)
                    .foregroundStyle(.statusInfo)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(store.detail.tabs.enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .kohereTextStyle(index == 0 ? .label2Semibold : .label2Medium)
                        .foregroundStyle(index == 0 ? .labelNormal : .neutral70)
                        .frame(width: 74, height: 44)
                        .overlay(alignment: .bottom) {
                            if index == 0 {
                                Rectangle()
                                    .fill(.primary50)
                                    .frame(height: 3)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 44)
        .background(.common0)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
        .zIndex(1)
    }

    private var contentSectionTabs: some View {
        sectionTabs
            .opacity(showsPinnedTabs ? 0 : 1)
    }

    private var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ListingDetailScrollOffsetPreferenceKey.self,
                value: proxy.frame(in: .global).minY
            )
        }
        .frame(height: 0)
    }

    private var tabsAndRoomOffersSection: some View {
        VStack(spacing: 0) {
            contentSectionTabs
            roomOffersSection
        }
    }

    private var roomOffersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ListingDetailSectionHeader(
                title: "각 방 정보",
                count: store.detail.roomOffers.count,
                showsChevron: true
            )
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.detail.roomOffers) { offer in
                        ListingDetailRoomOfferCard(offer: offer)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(.common0)
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                store.send(.likeButtonTapped)
            } label: {
                Image(store.detail.overview.isLiked ? "heart_fill_24" : "heart_24")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(store.detail.overview.isLiked ? .primary50 : .labelAlternative)
                    .frame(width: 48, height: 48)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.lineNormal, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button {
                store.send(.contactButtonTapped)
            } label: {
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

            Button {
                store.send(.applyButtonTapped)
            } label: {
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

private struct ListingDetailScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
