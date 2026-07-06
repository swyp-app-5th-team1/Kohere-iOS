//
//  MapListingSheetView.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct MapListingSheetView: View {
    let store: StoreOf<MapFeature>
    let contentBottomPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabber
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 10)

            filterRow
                .padding(.bottom, 8)

            listingRows
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

    private var grabber: some View {
        Capsule()
            .fill(.fillStrong)
            .frame(width: 40, height: 4)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    store.send(.filterButtonTapped)
                } label: {
                    ZStack {
                        Circle()
                            .fill(.coolNeutral5)
                            .frame(width: 32, height: 32)

                        Image("tune_24")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.labelAlternative)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("필터 설정"))

                ForEach(filterChips) { chip in
                    MapListingFilterChip(item: chip) {
                        store.send(.filterButtonTapped)
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private var filterChips: [MapListingFilterChipItem] {
        MapListingFilterChipItem.items(
            for: store.appliedFilter,
            source: store.appliedFilterSource
        )
    }

    private var listingRows: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if shouldShowEmptyState {
                    emptyListingView
                } else {
                    listingCardListView
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, contentBottomPadding)
        }
    }

    private var shouldShowEmptyState: Bool {
        guard store.listings.isEmpty,
              !store.isListingSearchLoading,
              !store.isRecommendationsLoading
        else { return false }

        switch store.listingSource {
        case .idle:
            return false

        case .locationSearch:
            return store.lastSearchedViewport != nil

        case .diagnosis:
            return true
        }
    }

    private var listingCardListView: some View {
        ForEach(store.listings) { item in
            ListingCardView(
                item: item,
                onCardTapped: {
                    store.send(.listingTapped(item.listingID))
                },
                onLikeTapped: {
                    store.send(.listingLikeButtonTapped(item.listingID))
                }
            )
            .onAppear {
                store.send(.listingRowAppeared(item.listingID))
            }
        }
    }

    private var emptyListingView: some View {
        VStack(spacing: 10) {
            Image(.circleInfo24)
                .foregroundStyle(.coolNeutral70)

            Text(emptyStateTitle)
                .kohereTextStyle(.body2Regular)
                .foregroundStyle(.labelNormal)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 176)
        .padding(.top, 18)
        .accessibilityElement(children: .combine)
    }

    private var emptyStateTitle: String {
        switch store.listingSource {
        case .diagnosis:
            return "조건에 맞는 집이 아직 없어요"

        case .idle, .locationSearch:
            return "이 지역에는 매물이 없어요"
        }
    }
}
