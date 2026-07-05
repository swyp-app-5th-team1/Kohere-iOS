//
//  Auth.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

nonisolated struct Auth: Equatable, Codable {
    let onboardingRequired: Bool
    let status: AuthStatus
    let tokenType: String
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
}

nonisolated struct AuthToken: Equatable, Codable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

nonisolated enum AuthStatus: String, Equatable, Codable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case unknown
}

enum SocialLoginCredential: Equatable, Sendable {
    case google(idToken: String)
    case apple(authorizationCode: String)
}

struct PhoneVerificationCode: Equatable {
    let message: String?
    let phoneNumber: String?
    let expiresIn: Int
}

struct PhoneVerification: Equatable {
    let phoneNumber: String
    let verified: Bool
}

struct EmailVerificationCode: Equatable {
    let message: String?
    let email: String
    let expiresIn: Int
}

struct EmailVerification: Equatable {
    let email: String
    let verified: Bool
}

struct TermsAgreement: Equatable {
    let status: String
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
    let agreedAt: String
}

struct AuthOnboardingProfile: Equatable {
    let firstName: String
    let lastName: String
    let gender: Gender
    let birthDate: String
    let country: String
    let occupation: Occupation
    let email: String
    let visaType: VisaType
}

struct LandlordOnboardingProfile: Equatable {
    let name: String
    let phoneNumber: String
}
