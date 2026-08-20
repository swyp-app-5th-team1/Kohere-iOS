//
//  AuthResponseDTO.swift
//  Kohere
//
//  Created by soomin on 6/30/26.
//

struct SocialLoginResponseDTO: Decodable {
    let onboardingRequired: Bool
    let status: String
    let tokenType: String
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let email: String?
    let name: String?
}

struct TokenResponseDTO: Decodable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct PhoneVerificationCodeResponseDTO: Decodable {
    let message: String?
    let phoneNumber: String?
    let expiresIn: Int
}

struct PhoneVerificationResponseDTO: Decodable {
    let phoneNumber: String
    let verified: Bool
}

struct EmailVerificationCodeResponseDTO: Decodable {
    let message: String?
    let email: String
    let expiresIn: Int
}

struct EmailVerificationResponseDTO: Decodable {
    let email: String
    let verified: Bool
}

struct TermsAgreementResponseDTO: Decodable {
    let status: String
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
    let agreedAt: String
}

struct AuthOnboardingResponseDTO: Decodable {
    let user: AuthOnboardingUserResponseDTO
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct AuthOnboardingUserResponseDTO: Decodable {
    let status: String
}
