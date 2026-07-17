//
//  MapListingFilterChipItem.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import Foundation

struct MapListingFilterChipItem: Identifiable {
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
                title: String(localized: "map.filter.section.options"),
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .options,
            title: RoomCondition.allCases
                .filter { filter.selectedOptions.contains($0) }
                .map(\.mapFilterDisplayTitle)
                .joined(separator: ", "),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func priceItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> MapListingFilterChipItem {
        guard filter.hasSelectedPriceRange || source == .diagnosis else {
            return MapListingFilterChipItem(
                kind: .price,
                title: String(localized: "map.filter.section.price"),
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .price,
            title: priceTitle(for: filter, source: source),
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
                title: String(localized: "map.filter.section.propertyType"),
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

    private static func priceTitle(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> String {
        let monthlyRentTitle = monthlyRentTitle(for: filter, source: source)
        let depositTitle = MapFilterPriceFormatter.chipTitle(
            prefix: String(localized: "map.filter.deposit"),
            selection: filter.depositRange,
            defaultSelection: MapFilterPriceRange.defaultDeposit
        )

        let title = [monthlyRentTitle, depositTitle]
            .compactMap { $0 }
            .joined(separator: ", ")

        return title.isEmpty ? String(localized: "map.filter.section.price") : title
    }

    private static func monthlyRentTitle(
        for filter: MapFilterState,
        source: MapFilterApplicationSource
    ) -> String? {
        switch source {
        case .manual:
            MapFilterPriceFormatter.chipTitle(
                prefix: String(localized: "map.filter.monthlyRent"),
                selection: filter.monthlyRentRange,
                defaultSelection: MapFilterPriceRange.defaultMonthlyRent
            )
        case .diagnosis:
            MapFilterPriceFormatter.chipTitle(
                prefix: String(localized: "map.filter.monthlyRent"),
                selection: filter.monthlyRentRange,
                bounds: MapFilterPriceRange.monthlyRent
            )
        }
    }
}
