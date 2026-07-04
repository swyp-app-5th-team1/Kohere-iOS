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
}
