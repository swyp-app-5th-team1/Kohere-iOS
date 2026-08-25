//
//  MapListingSearchInputMapper.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

extension MapFilterState {
    func listingSearchInput(
        bounds: MapBounds,
        page: Int = 0,
        size: Int = ListingSearchInput.defaultPageSize,
        source: MapFilterApplicationSource = .manual
    ) -> ListingSearchInput {
        ListingSearchInput(
            bounds: bounds,
            page: page,
            size: size,
            minBudget: monthlyRentRange.minimumSearchValue(
                defaultValue: monthlyRentDefaultMinimum(for: source)
            ),
            maxBudget: monthlyRentRange.maximumSearchValue(
                defaultValue: monthlyRentDefaultMaximum(for: source)
            ),
            minDeposit: depositRange.minimumSearchValue(
                defaultValue: MapFilterPriceRange.defaultDeposit.minimum
            ),
            maxDeposit: depositRange.maximumSearchValue(
                defaultValue: MapFilterPriceRange.defaultDeposit.maximum
            ),
            propertyTypes: selectedPropertyTypes
                .map(\.listingSearchPropertyType)
                .sorted(by: { $0.rawValue < $1.rawValue }),
            conditions: selectedOptions
                .filter { $0 != .noARCRequired }
                .sorted(by: { $0.rawValue < $1.rawValue })
        )
    }
}

private extension MapFilterState {
    func monthlyRentDefaultMinimum(for source: MapFilterApplicationSource) -> Int {
        switch source {
        case .manual:
            MapFilterPriceRange.defaultMonthlyRent.minimum
        case .diagnosis:
            MapFilterPriceRange.monthlyRent.lowerBound
        }
    }

    func monthlyRentDefaultMaximum(for source: MapFilterApplicationSource) -> Int {
        switch source {
        case .manual:
            MapFilterPriceRange.defaultMonthlyRent.maximum
        case .diagnosis:
            MapFilterPriceRange.monthlyRent.upperBound
        }
    }
}

private extension RangeSliderValue {
    static let wonMultiplier = 10_000

    func minimumSearchValue(defaultValue: Int) -> Int? {
        guard minimum != defaultValue else { return nil }
        return minimum * Self.wonMultiplier
    }

    func maximumSearchValue(defaultValue: Int) -> Int? {
        guard maximum != defaultValue else { return nil }
        return maximum * Self.wonMultiplier
    }
}

private extension MapPropertyType {
    var listingSearchPropertyType: ListingSearchPropertyType {
        switch self {
        case .goshiwon:
            .goshiwon
        case .coLiving:
            .coLiving
        case .shareHouse:
            .shareHouse
        }
    }
}
