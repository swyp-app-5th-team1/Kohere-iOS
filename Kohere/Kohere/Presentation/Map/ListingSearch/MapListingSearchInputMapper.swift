//
//  MapListingSearchInputMapper.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

extension MapFilterState {
    func listingSearchInput(
        bounds: MapBounds? = nil,
        listingIDs: [String] = [],
        page: Int = 0,
        size: Int = ListingSearchInput.defaultPageSize
    ) -> ListingSearchInput {
        ListingSearchInput(
            bounds: bounds,
            listingIDs: listingIDs,
            page: page,
            size: size,
            minBudget: monthlyRentRange.minimumSearchValue(
                unboundedValue: MapFilterPriceRange.monthlyRent.lowerBound
            ),
            maxBudget: monthlyRentRange.maximumSearchValue(
                unboundedValue: MapFilterPriceRange.monthlyRent.upperBound
            ),
            minDeposit: depositRange.minimumSearchValue(
                unboundedValue: MapFilterPriceRange.deposit.lowerBound
            ),
            maxDeposit: depositRange.maximumSearchValue(
                unboundedValue: MapFilterPriceRange.deposit.upperBound
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

private extension RangeSliderValue {
    static let wonMultiplier = 10_000

    func minimumSearchValue(unboundedValue: Int) -> Int? {
        guard minimum != unboundedValue else { return nil }
        return minimum * Self.wonMultiplier
    }

    func maximumSearchValue(unboundedValue: Int) -> Int? {
        guard maximum != unboundedValue else { return nil }
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
