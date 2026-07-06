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
        size: Int = ListingSearchInput.defaultPageSize
    ) -> ListingSearchInput {
        ListingSearchInput(
            bounds: bounds,
            page: page,
            size: size,
            minBudget: monthlyRentRange.minimumSearchValue(
                defaultValue: MapFilterPriceRange.defaultMonthlyRent.minimum
            ),
            maxBudget: monthlyRentRange.maximumSearchValue(
                defaultValue: MapFilterPriceRange.defaultMonthlyRent.maximum
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
            conditions: selectedOptions.sorted(by: { $0.rawValue < $1.rawValue })
        )
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
