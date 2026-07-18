//
//  UserProfile.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

struct UserProfile: Equatable, Sendable {
    let id: Int
    let userType: UserType
    let firstName: String?
    let lastName: String?
    let name: String?
    let nickname: String
    let gender: String?
    let birthDate: String?
    let country: String?
    let countryName: String?
    let countryFlag: URL?
    let occupation: String?
    let email: String?
    let visaType: String?
    let phoneNumber: String?
    let businessRegistrationNumber: String?
    let status: AuthStatus
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
    let createdAt: String
}

struct UserProfileUpdate: Equatable, Sendable {
    let firstName: String?
    let lastName: String?
    let gender: Gender?
    let birthDate: String?
    let country: String?
    let occupation: Occupation?
    let visaType: VisaType?
    let name: String?
    let phoneNumber: String?
    let marketingAgreed: Bool?
    let lang: String?

    init(
        firstName: String? = nil,
        lastName: String? = nil,
        gender: Gender? = nil,
        birthDate: String? = nil,
        country: String? = nil,
        occupation: Occupation? = nil,
        visaType: VisaType? = nil,
        name: String? = nil,
        phoneNumber: String? = nil,
        marketingAgreed: Bool? = nil,
        lang: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.birthDate = birthDate
        self.country = country
        self.occupation = occupation
        self.visaType = visaType
        self.name = name
        self.phoneNumber = phoneNumber
        self.marketingAgreed = marketingAgreed
        self.lang = lang
    }
}

enum UserType: String, Equatable, Sendable {
    case tenant = "TENANT"
    case landlord = "LANDLORD"
    case unknown
}
