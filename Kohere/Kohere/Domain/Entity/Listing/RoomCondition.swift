//
//  RoomCondition.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import Foundation

enum RoomCondition: String, CaseIterable, Hashable, Sendable {
    case moveInNow = "Move-in Now"
    case femaleOnly = "Female Only"
    case mealsIncluded = "Meals Included"
    case doubleRoom = "Double Room"
    case privateBathroom = "Private Bath"
    case englishSupport = "English OK"
    case addressRegistration = "Address Registration"
    case noMaintenanceFee = "No Maint. Fee"
    case noARCRequired = "No ARC"

    var displayTitle: String {
        rawValue
    }

    nonisolated init?(conditionCode: String) {
        switch conditionCode.uppercased() {
        case "MOVE_IN_NOW":
            self = .moveInNow
        case "FEMALE_ONLY":
            self = .femaleOnly
        case "MEALS_INCLUDED":
            self = .mealsIncluded
        case "DOUBLE_ROOM":
            self = .doubleRoom
        case "PRIVATE_BATH":
            self = .privateBathroom
        case "ENGLISH_OK":
            self = .englishSupport
        case "ADDRESS_REGISTRATION":
            self = .addressRegistration
        case "NO_MAINT_FEE":
            self = .noMaintenanceFee
        case "NO_ARC":
            self = .noARCRequired
        default:
            return nil
        }
    }

    nonisolated var conditionCode: String {
        switch self {
        case .moveInNow:
            "MOVE_IN_NOW"
        case .femaleOnly:
            "FEMALE_ONLY"
        case .mealsIncluded:
            "MEALS_INCLUDED"
        case .doubleRoom:
            "DOUBLE_ROOM"
        case .privateBathroom:
            "PRIVATE_BATH"
        case .englishSupport:
            "ENGLISH_OK"
        case .addressRegistration:
            "ADDRESS_REGISTRATION"
        case .noMaintenanceFee:
            "NO_MAINT_FEE"
        case .noARCRequired:
            "NO_ARC"
        }
    }
}
