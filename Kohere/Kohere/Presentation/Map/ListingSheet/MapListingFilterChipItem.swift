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
        source: MapFilterApplicationSource,
        locale: Locale
    ) -> [MapListingFilterChipItem] {
        [
            optionsItem(for: filter, source: source, locale: locale),
            priceItem(for: filter, source: source, locale: locale),
            propertyTypeItem(for: filter, source: source, locale: locale)
        ]
    }

    private static func optionsItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource,
        locale: Locale
    ) -> MapListingFilterChipItem {
        let language = AppLanguage(locale: locale)
        guard filter.hasSelectedOptions else {
            return MapListingFilterChipItem(
                kind: .options,
                title: language.localized(.mapFilterSectionOptions),
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .options,
            title: RoomCondition.allCases
                .filter { filter.selectedOptions.contains($0) }
                .map { $0.mapFilterDisplayTitle(locale: locale) }
                .joined(separator: ", "),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func priceItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource,
        locale: Locale
    ) -> MapListingFilterChipItem {
        let language = AppLanguage(locale: locale)
        guard filter.hasSelectedPriceRange else {
            return MapListingFilterChipItem(
                kind: .price,
                title: language.localized(.mapFilterSectionPrice),
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .price,
            title: priceTitle(for: filter, locale: locale),
            style: style(for: source),
            showsChevron: false
        )
    }

    private static func propertyTypeItem(
        for filter: MapFilterState,
        source: MapFilterApplicationSource,
        locale: Locale
    ) -> MapListingFilterChipItem {
        let language = AppLanguage(locale: locale)
        guard filter.hasSelectedPropertyTypes else {
            return MapListingFilterChipItem(
                kind: .propertyType,
                title: language.localized(.mapFilterSectionPropertyType),
                style: .plain,
                showsChevron: true
            )
        }

        return MapListingFilterChipItem(
            kind: .propertyType,
            title: MapPropertyType.allCases
                .filter { filter.selectedPropertyTypes.contains($0) }
                .map { $0.displayTitle(locale: locale) }
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
        locale: Locale
    ) -> String {
        let language = AppLanguage(locale: locale)
        let monthlyRentTitle = MapFilterPriceFormatter.chipTitle(
            prefix: language.localized(.mapFilterMonthlyRent),
            selection: filter.monthlyRentRange,
            bounds: MapFilterPriceRange.monthlyRent,
            locale: locale
        )
        let depositTitle = MapFilterPriceFormatter.chipTitle(
            prefix: language.localized(.mapFilterDeposit),
            selection: filter.depositRange,
            bounds: MapFilterPriceRange.deposit,
            locale: locale
        )

        let title = [monthlyRentTitle, depositTitle]
            .compactMap { $0 }
            .joined(separator: ", ")

        return title.isEmpty ? language.localized(.mapFilterSectionPrice) : title
    }
}
