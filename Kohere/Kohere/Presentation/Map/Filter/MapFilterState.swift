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
        monthlyRentRange != MapFilterPriceRange.defaultMonthlyRent || depositRange != MapFilterPriceRange.defaultDeposit
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
            String(localized: "Move-in Now")
        case .femaleOnly:
            String(localized: "Female Only")
        case .mealsIncluded:
            String(localized: "Meals Included")
        case .doubleRoom:
            String(localized: "Double Room")
        case .privateBathroom:
            String(localized: "Private Bath")
        case .englishSupport:
            String(localized: "English OK")
        case .addressRegistration:
            String(localized: "Address Registration")
        case .noMaintenanceFee:
            String(localized: "No Maint. Fee")
        case .noARCRequired:
            String(localized: "No ARC")
        }
    }
}

enum MapFilterPriceRange {
    static let monthlyRent = 0...100
    static let deposit = 0...300

    static let defaultMonthlyRent = RangeSliderValue(
        minimum: monthlyRent.lowerBound,
        maximum: 50,
        bounds: monthlyRent
    )
    static let defaultDeposit = RangeSliderValue(
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
            String(localized: "고시원")
        case .coLiving:
            String(localized: "코리빙")
        case .shareHouse:
            String(localized: "쉐어하우스")
        }
    }
}
