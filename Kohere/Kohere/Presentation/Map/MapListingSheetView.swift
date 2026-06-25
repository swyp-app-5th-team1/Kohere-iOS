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
                .padding(.horizontal, 20)
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
                    Image("tune_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.labelAlternative)
                        .frame(width: 32, height: 32)
                        .background(.coolNeutral5)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ForEach(filterChips) { chip in
                    FilterChip(item: chip) {
                        store.send(.filterButtonTapped)
                    }
                }
            }
            .padding(.vertical, 1)
        }
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
                        ListingPreviewRow()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 104)
        }
    }
}

private struct MapListingFilterChipItem: Identifiable {
    enum Kind: Hashable {
        case options
        case price
        case propertyType
    }

    enum Style {
        case plain
        case manual
        case diagnosis
    }

    let kind: Kind
    let title: String
    let style: Style
    let showsChevron: Bool

    var id: Kind { kind }

    static func items(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> [MapListingFilterChipItem] {
        [
            optionsItem(for: filter, source: source),
            priceItem(for: filter, source: source),
            propertyTypeItem(for: filter, source: source)
        ]
    }

    private static func optionsItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> MapListingFilterChipItem {
        guard filter.hasSelectedOptions else {
            return MapListingFilterChipItem(
                kind: .options,
                title: "매물 옵션",
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .options,
            title: MapFilterOption.allCases
                .filter { filter.selectedOptions.contains($0) }
                .map(\.displayTitle)
                .joined(separator: ", "),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func priceItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> MapListingFilterChipItem {
        guard filter.hasSelectedPriceRange else {
            return MapListingFilterChipItem(
                kind: .price,
                title: "가격",
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .price,
            title: priceTitle(for: filter),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func propertyTypeItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> MapListingFilterChipItem {
        guard filter.hasSelectedPropertyTypes else {
            return MapListingFilterChipItem(
                kind: .propertyType,
                title: "매물 종류",
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .propertyType,
            title: MapPropertyType.allCases
                .filter { filter.selectedPropertyTypes.contains($0) }
                .map(\.displayTitle)
                .joined(separator: ", "),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func style(for source: MapFilterApplicationSource) -> Style {
        switch source {
        case .manual:
            .manual
        case .diagnosis:
            .diagnosis
        }
    }

    private static func priceTitle(for filter: MapFilterState) -> String {
        let monthlyRentTitle = rangeTitle(
            prefix: "월세",
            selection: filter.monthlyRentRange,
            defaultSelection: MapFilterPriceRange.defaultMonthlyRent
        )
        let depositTitle = rangeTitle(
            prefix: "보증금",
            selection: filter.depositRange,
            defaultSelection: MapFilterPriceRange.defaultDeposit
        )

        return [monthlyRentTitle, depositTitle]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private static func rangeTitle(
        prefix: String,
        selection: MapFilterPriceSelection,
        defaultSelection: MapFilterPriceSelection
    ) -> String? {
        guard selection != defaultSelection else { return nil }

        switch (selection.minimum, selection.maximum) {
        case (defaultSelection.minimum, let maximum):
            return "\(prefix) \(maximum)만 원 이하"
        case (let minimum, defaultSelection.maximum):
            return "\(prefix) \(minimum)만 원 이상"
        case let (minimum, maximum):
            return "\(prefix) \(minimum)만~\(maximum)만 원"
        }
    }
}

private struct FilterChip: View {
    let item: MapListingFilterChipItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(item.title)
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(foregroundStyle)

                if item.showsChevron {
                    Image(.chevronDownFill16)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.labelNeutral)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(.coolNeutral5)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(borderStyle, lineWidth: item.style == .plain ? 0 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundStyle: Color {
        switch item.style {
        case .plain, .manual:
            .labelNeutral
        case .diagnosis:
            .primaryPress
        }
    }

    private var borderStyle: Color {
        switch item.style {
        case .plain:
            .clear
        case .manual:
            .labelStrong
        case .diagnosis:
            .primaryPress
        }
    }
}

private struct ListingPreviewRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.backgroundNormalAlternative)
                .frame(width: 112, height: 112)
                .overlay {
                    Image("home_fill_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.labelAssistive)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("₩380~400K/mo")
                            .kohereTextStyle(.label1Semibold)
                            .foregroundStyle(.labelNormal)

                        Text("≈$355~398/mo")
                            .kohereTextStyle(.label3Medium)
                            .foregroundStyle(.labelNormal)
                    }

                    Spacer(minLength: 0)

                    Image("heart_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.labelAlternative)
                }

                Text("Dep. ₩200K · Maint. ₩20K")
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.labelAlternative)

                Text("8-min walk Hongdae Sta.")
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.labelAlternative)

                HStack(spacing: 6) {
                    Text("Goshiwon")
                        .kohereTextStyle(.caption2Medium)
                        .foregroundStyle(.labelNeutral)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(.backgroundNormalAlternative)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text("1 mo~")
                        .kohereTextStyle(.caption2Medium)
                        .foregroundStyle(.labelAlternative)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
