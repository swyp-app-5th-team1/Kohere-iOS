//
//  UserRequestDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

nonisolated struct UpdateNotificationPreferencesRequestDTO: Encodable, Sendable {
    let chatPushEnabled: Bool
}

nonisolated struct UpdateProfileRequestDTO: Encodable, Sendable {
    let gender: String?
    let birthDate: String?
    let country: String?
    let occupation: String?
    let visaType: String?
    let name: String?
    let phoneNumber: String?
    let marketingAgreed: Bool?
    let lang: String?

    init(_ update: UserProfileUpdate) {
        gender = update.gender?.rawValue
        birthDate = update.birthDate
        country = update.country
        occupation = update.occupation?.rawValue
        visaType = update.visaType?.rawValue
        name = update.name
        phoneNumber = update.phoneNumber
        marketingAgreed = update.marketingAgreed
        lang = update.lang
    }
}
