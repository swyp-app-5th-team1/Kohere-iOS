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
            language.localized("map.propertyType.goshiwon")
        case .coLiving:
            language.localized("map.propertyType.coLiving")
        case .shareHouse:
            language.localized("map.propertyType.shareHouse")
        }
    }
}

extension RoomCondition {
    func mapFilterDisplayTitle(locale: Locale) -> String {
        let language = AppLanguage(locale: locale)
        return switch self {
        case .moveInNow:
            language.localized("map.filter.option.moveInNow")
        case .femaleOnly:
            language.localized("map.filter.option.femaleOnly")
        case .mealsIncluded:
            language.localized("map.filter.option.mealsIncluded")
        case .doubleRoom:
            language.localized("map.filter.option.doubleRoom")
        case .privateBathroom:
            language.localized("map.filter.option.privateBathroom")
        case .englishSupport:
            language.localized("map.filter.option.englishSupport")
        case .addressRegistration:
            language.localized("map.filter.option.addressRegistration")
        case .noMaintenanceFee:
            language.localized("map.filter.option.noMaintenanceFee")
        case .noARCRequired:
            language.localized("map.filter.option.noARCRequired")
        }
    }
}
