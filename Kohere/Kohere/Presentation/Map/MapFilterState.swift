//
//  MapFilterState.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import Foundation

struct MapFilterState: Equatable {
    var selectedOptions: Set<MapFilterOption> = []

    var monthlyRentRange = MapFilterPriceRange.defaultMonthlyRent
    var depositRange = MapFilterPriceRange.defaultDeposit

    var selectedPropertyTypes: Set<MapPropertyType> = []
}

enum MapFilterApplicationSource: Equatable {
    case manual
    case diagnosis
}

extension MapFilterState {
    var isDefault: Bool {
        self == MapFilterState()
    }

    var hasSelectedOptions: Bool {
        !selectedOptions.isEmpty
    }

    var hasSelectedPriceRange: Bool {
        monthlyRentRange != MapFilterPriceRange.defaultMonthlyRent
            || depositRange != MapFilterPriceRange.defaultDeposit
    }

    var hasSelectedPropertyTypes: Bool {
        !selectedPropertyTypes.isEmpty
    }

    mutating func toggleOption(_ option: MapFilterOption) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }

    mutating func togglePropertyType(_ propertyType: MapPropertyType) {
        if selectedPropertyTypes.contains(propertyType) {
            selectedPropertyTypes.remove(propertyType)
        } else {
            selectedPropertyTypes.insert(propertyType)
        }
    }

    mutating func updateMonthlyRentMinimum(_ minimum: Int) {
        monthlyRentRange.updateMinimum(minimum, bounds: MapFilterPriceRange.monthlyRent)
    }

    mutating func updateMonthlyRentMaximum(_ maximum: Int) {
        monthlyRentRange.updateMaximum(maximum, bounds: MapFilterPriceRange.monthlyRent)
    }

    mutating func updateDepositMinimum(_ minimum: Int) {
        depositRange.updateMinimum(minimum, bounds: MapFilterPriceRange.deposit)
    }

    mutating func updateDepositMaximum(_ maximum: Int) {
        depositRange.updateMaximum(maximum, bounds: MapFilterPriceRange.deposit)
    }
}

enum MapFilterOption: CaseIterable, Hashable {
    case moveInNow
    case femaleOnly
    case mealsIncluded
    case doubleRoom
    case privateBathroom
    case englishSupport
    case addressRegistration
    case noMaintenanceFee
    case noARCRequired

    var displayTitle: String {
        switch self {
        case .moveInNow:
            "Move-in Now"
        case .femaleOnly:
            "Female Only"
        case .mealsIncluded:
            "Meals Included"
        case .doubleRoom:
            "Double Room"
        case .privateBathroom:
            "Private Bath"
        case .englishSupport:
            "English OK"
        case .addressRegistration:
            "Address Registration"
        case .noMaintenanceFee:
            "No Maint. Fee"
        case .noARCRequired:
            "No ARC"
        }
    }
}

struct MapFilterPriceSelection: Equatable {
    var minimum: Int
    var maximum: Int

    init(minimum: Int, maximum: Int, bounds: ClosedRange<Int>) {
        let clampedMinimum = min(max(minimum, bounds.lowerBound), bounds.upperBound)
        let clampedMaximum = min(max(maximum, bounds.lowerBound), bounds.upperBound)

        self.minimum = min(clampedMinimum, clampedMaximum)
        self.maximum = max(clampedMinimum, clampedMaximum)
    }

    mutating func updateMinimum(_ value: Int, bounds: ClosedRange<Int>) {
        minimum = min(max(value, bounds.lowerBound), maximum)
    }

    mutating func updateMaximum(_ value: Int, bounds: ClosedRange<Int>) {
        maximum = max(min(value, bounds.upperBound), minimum)
    }
}

enum MapFilterPriceRange {
    static let monthlyRent = 0...100
    static let deposit = 0...300

    static let defaultMonthlyRent = MapFilterPriceSelection(
        minimum: monthlyRent.lowerBound,
        maximum: 50,
        bounds: monthlyRent
    )
    static let defaultDeposit = MapFilterPriceSelection(
        minimum: deposit.lowerBound,
        maximum: 150,
        bounds: deposit
    )
}

enum MapPropertyType: CaseIterable, Hashable {
    case goshiwon
    case coLiving
    case shareHouse

    var displayTitle: String {
        switch self {
        case .goshiwon:
            "고시원"
        case .coLiving:
            "코리빙"
        case .shareHouse:
            "쉐어하우스"
        }
    }
}
