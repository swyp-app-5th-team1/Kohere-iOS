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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabber
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
                .padding(.bottom, 14)

            filterRow
                .padding(.bottom, 18)

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
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        store.send(.listingTapped("preview-listing-\(index)"))
                    } label: {
                        MapListingPreviewRow()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 104)
        }
    }
}
