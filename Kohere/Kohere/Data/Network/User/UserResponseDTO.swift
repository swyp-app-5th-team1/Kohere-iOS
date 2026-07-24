//
//  UserResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

struct UserProfileResponseDTO: Decodable {
    let id: Int
    let userType: String
    let name: String?
    let nickname: String?
    let gender: String?
    let birthDate: String?
    let country: String?
    let countryName: String?
    let countryFlag: String?
    let occupation: String?
    let email: String?
    let visaType: String?
    let phoneNumber: String?
    let businessRegistrationNumber: String?
    let status: String
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
    let lang: String?
    let createdAt: String
}
