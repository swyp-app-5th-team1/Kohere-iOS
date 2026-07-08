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

enum UserType: String, Equatable, Sendable {
    case tenant = "TENANT"
    case landlord = "LANDLORD"
    case unknown
}
