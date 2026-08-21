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
    @State private var sectionMinYBySection: [ListingDetailSection: CGFloat] = [:]
    @State private var resolvedScrollView: UIScrollView?

    private let collapsedNavigationBarHeight: CGFloat = 100
    private let collapsedNavigationBarThreshold: CGFloat = 211
    private let sectionTabsPinOffset: CGFloat = 356
    private let sectionTabsHeight: CGFloat = 44
    private let bottomContentPadding: CGFloat = 20
    private let detailScrollCoordinateSpace = "ListingDetailScrollCoordinateSpace"

    private var stickyHeaderHeight: CGFloat {
        collapsedNavigationBarHeight + sectionTabsHeight
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            Group {
                if let detail = store.detail {
                    loadedContent(detail: detail, scrollProxy: scrollProxy)
                } else {
                    Color.neutral5
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .interactivePopGestureEnabled()
        }
    }

    private func loadedContent(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        ZStack(alignment: .top) {
            detailScrollView(detail: detail, scrollProxy: scrollProxy)
                .accessibilityHidden(store.isApplicationSheetPresented)

            topChromeOverlay(detail: detail, scrollProxy: scrollProxy)
                .accessibilityHidden(store.isApplicationSheetPresented)

            if store.isApplicationSheetPresented {
                ListingDetailApplicationSheetOverlay(
                    roomOffers: detail.roomOffers,
                    selectedRoomOfferID: store.selectedRoomOfferID,
                    isRoomTypeSelectorPresented: store.isRoomTypeSelectorPresented,
                    validationMessage: store.roomTypeValidationMessage,
                    onDismiss: { store.send(.applicationSheetDismissed) },
                    onRoomTypeSelectorTap: { store.send(.roomTypeSelectorTapped) },
                    onRoomOfferTap: { store.send(.roomOfferSelected($0)) },
                    onApplyTap: { store.send(.applyButtonTapped) }
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.showsTenantActionBar && !store.isApplicationSheetPresented {
                bottomBar(detail: detail)
            }
        }
        .background(.neutral5)
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut(duration: 0.2), value: store.isApplicationSheetPresented)
    }

    private func detailScrollView(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        Group {
            if #available(iOS 18.0, *) {
                baseScrollView(detail: detail, scrollProxy: scrollProxy)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, offset in
                        updateScrollPosition(offset)
                    }
            } else {
                baseScrollView(detail: detail, scrollProxy: scrollProxy)
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

    private func baseScrollView(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                scrollOffsetReader

                VStack(spacing: 16) {
                    ListingDetailHeroSection(overview: detail.overview)
                    tabsAndRoomOffersSection(detail: detail, scrollProxy: scrollProxy)
                    ListingDetailContentSections(
                        detail: detail,
                        appLanguage: store.appLanguage,
                        title: { title(for: $0, detail: detail) },
                        onMapPreviewTapped: { store.send(.mapPreviewTapped) },
                        sectionWrapper: { section, content in
                            AnyView(trackedSection(section) { content })
                        }
                    )
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

        // 탭으로 이동한 뒤 보이는 후행 섹션이 선택값을 덮지 않도록, 손 스크롤 전까지 선택을 유지한다.
        if pendingProgrammaticScrollSection != nil {
            guard isUserDrivenScroll else { return }
            pendingProgrammaticScrollSection = nil
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
        pendingProgrammaticScrollSection = section

        if selectedSection != section {
            selectedSection = section
        }
    }

    private var isUserDrivenScroll: Bool {
        guard let scrollView = resolvedScrollView else { return false }
        return scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
    }

    private func topChromeOverlay(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        VStack(spacing: 0) {
            ListingDetailTopNavigationBar(
                progress: topChromeProgress,
                height: collapsedNavigationBarHeight,
                onBackTap: { store.send(.backButtonTapped) }
            )

            if showsPinnedTabs {
                sectionTabs(detail: detail, scrollProxy: scrollProxy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(2)
    }

    private func sectionTabs(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        ListingDetailSectionTabs(
            selectedSection: selectedSection,
            title: { title(for: $0, detail: detail) },
            onTap: { section in
                scrollToSection(section, scrollProxy: scrollProxy)
            }
        )
    }

    private func title(
        for section: ListingDetailSection,
        detail: ListingDetailModel
    ) -> String {
        let index = section.rawValue
        guard detail.tabs.indices.contains(index) else {
            return section.fallbackTitle(language: store.appLanguage)
        }
        return detail.tabs[index]
    }

    private func contentSectionTabs(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        sectionTabs(detail: detail, scrollProxy: scrollProxy)
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

    private func tabsAndRoomOffersSection(
        detail: ListingDetailModel,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        VStack(spacing: 0) {
            contentSectionTabs(detail: detail, scrollProxy: scrollProxy)
            trackedSection(.roomOffers) {
                ListingDetailRoomOffersSection(
                    title: title(for: .roomOffers, detail: detail),
                    roomOffers: detail.roomOffers
                )
            }
        }
    }

    private func bottomBar(detail: ListingDetailModel) -> some View {
        ListingDetailBottomBar(
            isLiked: detail.overview.isLiked,
            showsLikeButton: store.showsFavoriteControl,
            isApplyEnabled: store.canUseApplicationFeatures,
            onLikeTap: { store.send(.likeButtonTapped) },
            onContactTap: { store.send(.contactButtonTapped) },
            onApplyTap: { store.send(.applyButtonTapped) }
        )
    }
}
