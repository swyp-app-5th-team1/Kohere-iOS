//
//  RoomCondition.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import Foundation

enum RoomCondition: String, CaseIterable, Hashable {
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
        case "PRIVATE_BATHROOM":
            self = .privateBathroom
        case "ENGLISH_SUPPORT":
            self = .englishSupport
        case "ADDRESS_REGISTRATION":
            self = .addressRegistration
        case "NO_MAINT_FEE":
            self = .noMaintenanceFee
        case "NO_ARC_REQUIRED":
            self = .noARCRequired
        default:
            self.init(rawValue: conditionCode)
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
            "PRIVATE_BATHROOM"
        case .englishSupport:
            "ENGLISH_SUPPORT"
        case .addressRegistration:
            "ADDRESS_REGISTRATION"
        case .noMaintenanceFee:
            "NO_MAINT_FEE"
        case .noARCRequired:
            "NO_ARC_REQUIRED"
        }
    }
}
