//
//  ListingDetailView.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct ListingDetailView: View {
    let store: StoreOf<ListingDetailFeature>
    @State private var topChromeProgress: CGFloat = 0
    @State private var verticalScrollOffset: CGFloat = 0
    @State private var fallbackScrollOffsetBaseline: CGFloat?
    @State private var showsPinnedTabs = false
    @State private var selectedSection: ListingDetailSection = .roomOffers
    @State private var pendingProgrammaticScrollSection: ListingDetailSection?
    @State private var programmaticScrollSelectionRevision = 0
    @State private var sectionMinYBySection: [ListingDetailSection: CGFloat] = [:]
    @State private var resolvedScrollView: UIScrollView?

    private let collapsedNavigationBarHeight: CGFloat = 100
    private let collapsedNavigationBarThreshold: CGFloat = 211
    private let sectionTabsPinOffset: CGFloat = 356
    private let sectionTabsHeight: CGFloat = 44
    private let bottomContentPadding: CGFloat = 20
    private let programmaticScrollSelectionFallbackDelay: TimeInterval = 0.6
    private let detailScrollCoordinateSpace = "ListingDetailScrollCoordinateSpace"

    private var stickyHeaderHeight: CGFloat {
        collapsedNavigationBarHeight + sectionTabsHeight
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .top) {
                detailScrollView(scrollProxy: scrollProxy)

                topChromeOverlay(scrollProxy: scrollProxy)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .background(.neutral5)
            .ignoresSafeArea(edges: .top)
        }
    }

    private func detailScrollView(scrollProxy: ScrollViewProxy) -> some View {
        Group {
            if #available(iOS 18.0, *) {
                baseScrollView(scrollProxy: scrollProxy)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, offset in
                        updateScrollPosition(offset)
                    }
            } else {
                baseScrollView(scrollProxy: scrollProxy)
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

    private func baseScrollView(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                scrollOffsetReader

                VStack(spacing: 16) {
                    ListingDetailHeroSection(overview: store.detail.overview)
                    tabsAndRoomOffersSection(scrollProxy: scrollProxy)
                    trackedSection(.price) {
                        ListingDetailInfoSection(title: "가격 정보", rows: store.detail.priceInfo)
                    }
                    trackedSection(.property) {
                        ListingDetailInfoSection(title: "매물 정보", rows: store.detail.propertyInfo)
                    }
                    trackedSection(.building) {
                        ListingDetailInfoSection(title: "건물 정보", rows: store.detail.buildingInfo)
                    }
                    trackedSection(.facility) {
                        ListingDetailInfoSection(title: "공용 시설", rows: store.detail.facilityInfo)
                    }
                    trackedSection(.location) {
                        ListingDetailLocationSection(locationInfo: store.detail.locationInfo)
                    }
                    trackedSection(.review) {
                        ListingDetailReviewSection(reviewCount: store.detail.overview.reviewCount)
                    }
                }
                .padding(.bottom, bottomContentPadding)
            }
            .background {
                ListingDetailScrollViewResolver { scrollView in
                    if resolvedScrollView !== scrollView {
                        resolvedScrollView = scrollView
                    }
                }
            }
        }
        .coordinateSpace(name: detailScrollCoordinateSpace)
        .onPreferenceChange(ListingDetailSectionPositionKey.self) { positions in
            updateSectionPositions(positions)
        }
    }

    @ViewBuilder
    private func trackedSection<Content: View>(
        _ section: ListingDetailSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .id(section)
            .background(alignment: .top) {
                sectionPositionReader(for: section)
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

    private func updateSectionPositions(_ positions: [ListingDetailSection: CGFloat]) {
        sectionMinYBySection = positions

        let topActivationY = stickyHeaderHeight + 1
        let topActivatedSection = ListingDetailSection.allCases.last { section in
            guard let minY = positions[section] else { return false }
            return minY <= topActivationY
        } ?? .roomOffers
        let activeSection = trailingVisibleSection(
            from: positions,
            topActivatedSection: topActivatedSection
        ) ?? topActivatedSection

        if let pendingProgrammaticScrollSection {
            if activeSection == pendingProgrammaticScrollSection {
                finishProgrammaticScrollSelection(for: pendingProgrammaticScrollSection)
            }
            return
        }

        if selectedSection != activeSection {
            selectedSection = activeSection
        }
    }

    private func scrollToSection(
        _ section: ListingDetailSection,
        scrollProxy: ScrollViewProxy
    ) {
        beginProgrammaticScrollSelection(to: section)

        guard let scrollView = resolvedScrollView,
              let sectionMinY = sectionMinYBySection[section] else {
            withAnimation(.snappy(duration: 0.35)) {
                scrollProxy.scrollTo(section, anchor: .top)
            }
            return
        }

        let desiredOffsetY = scrollView.contentOffset.y + sectionMinY - stickyHeaderHeight
        let minOffsetY = minScrollOffsetY(for: scrollView)
        let maxOffsetY = maxScrollOffsetY(for: scrollView)
        let targetOffsetY = min(max(desiredOffsetY, minOffsetY), maxOffsetY)

        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: targetOffsetY),
            animated: true
        )
    }

    private func trailingVisibleSection(
        from positions: [ListingDetailSection: CGFloat],
        topActivatedSection: ListingDetailSection
    ) -> ListingDetailSection? {
        guard let scrollView = resolvedScrollView,
              let topActivatedMinY = positions[topActivatedSection] else { return nil }

        let topActivationY = stickyHeaderHeight + 1
        let visibleBottomY = scrollView.bounds.height - scrollView.adjustedContentInset.bottom
        let maxOffsetY = maxScrollOffsetY(for: scrollView)
        let currentOffsetY = scrollView.contentOffset.y
        let topActivatedDistance = abs(topActivatedMinY - topActivationY)
        let isNearBottom = currentOffsetY >= maxOffsetY - 1

        let visibleTrailingCandidates = ListingDetailSection.allCases.compactMap { section -> (section: ListingDetailSection, distance: CGFloat)? in
            guard section.rawValue > topActivatedSection.rawValue,
                  let minY = positions[section] else { return nil }

            let minYAtMaxOffset = currentOffsetY + minY - maxOffsetY
            let cannotReachTopActivation = minYAtMaxOffset > topActivationY
            let distance = abs(minY - topActivationY)

            guard cannotReachTopActivation,
                  minY <= visibleBottomY else { return nil }

            return (section, distance)
        }

        if isNearBottom {
            return visibleTrailingCandidates.last?.section
        }

        return visibleTrailingCandidates.filter {
            $0.distance < topActivatedDistance
        }
        .min { lhs, rhs in
            lhs.distance < rhs.distance
        }?
        .section
    }

    private func minScrollOffsetY(for scrollView: UIScrollView) -> CGFloat {
        -scrollView.adjustedContentInset.top
    }

    private func maxScrollOffsetY(for scrollView: UIScrollView) -> CGFloat {
        max(
            minScrollOffsetY(for: scrollView),
            scrollView.contentSize.height
                - scrollView.bounds.height
                + scrollView.adjustedContentInset.bottom
        )
    }

    private func beginProgrammaticScrollSelection(to section: ListingDetailSection) {
        programmaticScrollSelectionRevision += 1
        let revision = programmaticScrollSelectionRevision

        pendingProgrammaticScrollSection = section

        if selectedSection != section {
            selectedSection = section
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + programmaticScrollSelectionFallbackDelay) {
            guard programmaticScrollSelectionRevision == revision,
                  pendingProgrammaticScrollSection == section else { return }
            finishProgrammaticScrollSelection(for: section)
        }
    }

    private func finishProgrammaticScrollSelection(for section: ListingDetailSection) {
        pendingProgrammaticScrollSection = nil

        if selectedSection != section {
            selectedSection = section
        }
    }

    private func topChromeOverlay(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            ListingDetailTopNavigationBar(
                progress: topChromeProgress,
                height: collapsedNavigationBarHeight,
                onBackTap: { store.send(.backButtonTapped) },
                onShareTap: { store.send(.shareButtonTapped) }
            )

            if showsPinnedTabs {
                sectionTabs(scrollProxy: scrollProxy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(2)
    }

    private func sectionTabs(scrollProxy: ScrollViewProxy) -> some View {
        ListingDetailSectionTabs(
            selectedSection: selectedSection,
            title: title(for:),
            onTap: { section in
                scrollToSection(section, scrollProxy: scrollProxy)
            }
        )
    }

    private func title(for section: ListingDetailSection) -> String {
        let index = section.rawValue
        guard store.detail.tabs.indices.contains(index) else { return section.fallbackTitle }
        return store.detail.tabs[index]
    }

    private func contentSectionTabs(scrollProxy: ScrollViewProxy) -> some View {
        sectionTabs(scrollProxy: scrollProxy)
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

    private func sectionPositionReader(for section: ListingDetailSection) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ListingDetailSectionPositionKey.self,
                value: [section: proxy.frame(in: .named(detailScrollCoordinateSpace)).minY]
            )
        }
    }

    private func tabsAndRoomOffersSection(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            contentSectionTabs(scrollProxy: scrollProxy)
            trackedSection(.roomOffers) {
                ListingDetailRoomOffersSection(roomOffers: store.detail.roomOffers)
            }
        }
    }

    private var bottomBar: some View {
        ListingDetailBottomBar(
            isLiked: store.detail.overview.isLiked,
            showsLikeButton: store.canUseFavoriteFeatures,
            onLikeTap: { store.send(.likeButtonTapped) },
            onContactTap: { store.send(.contactButtonTapped) },
            onApplyTap: { store.send(.applyButtonTapped) }
        )
    }
}
