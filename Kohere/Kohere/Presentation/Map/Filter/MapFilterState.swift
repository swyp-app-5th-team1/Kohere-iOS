//
//  MapFilterState.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import Foundation

struct MapFilterState: Equatable, Sendable {
    var selectedOptions: Set<RoomCondition> = []

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

    mutating func toggleOption(_ option: RoomCondition) {
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

enum MapPropertyType: CaseIterable, Hashable, Sendable {
    case goshiwon
    case coLiving
    case shareHouse

    func displayTitle(locale: Locale) -> String {
        let language = AppLanguage(locale: locale)
        return switch self {
        case .goshiwon:
            language.localized(.mapPropertyTypeGoshiwon)
        case .coLiving:
            language.localized(.mapPropertyTypeCoLiving)
        case .shareHouse:
            language.localized(.mapPropertyTypeShareHouse)
        }
    }
}

extension RoomCondition {
    func mapFilterDisplayTitle(locale: Locale) -> String {
        let language = AppLanguage(locale: locale)
        return switch self {
        case .moveInNow:
            language.localized(.mapFilterOptionMoveInNow)
        case .femaleOnly:
            language.localized(.mapFilterOptionFemaleOnly)
        case .mealsIncluded:
            language.localized(.mapFilterOptionMealsIncluded)
        case .doubleRoom:
            language.localized(.mapFilterOptionDoubleRoom)
        case .privateBathroom:
            language.localized(.mapFilterOptionPrivateBathroom)
        case .englishSupport:
            language.localized(.mapFilterOptionEnglishSupport)
        case .addressRegistration:
            language.localized(.mapFilterOptionAddressRegistration)
        case .noMaintenanceFee:
            language.localized(.mapFilterOptionNoMaintenanceFee)
        case .noARCRequired:
            language.localized(.mapFilterOptionNoARCRequired)
        }
    }
}
