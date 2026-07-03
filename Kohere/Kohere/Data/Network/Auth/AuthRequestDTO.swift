//
//  AuthRequestDTO.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

nonisolated struct SocialLoginRequestDTO: Encodable, Sendable {
    let provider: SocialLoginProviderDTO
    let idToken: String
}

enum SocialLoginProviderDTO: String, Encodable, Sendable {
    case google = "GOOGLE"
}

nonisolated struct ReissueTokenRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

nonisolated struct LogoutRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

nonisolated struct PhoneVerificationCodeRequestDTO: Encodable, Sendable {
    let phoneNumber: String
}

nonisolated struct PhoneVerificationRequestDTO: Encodable, Sendable {
    let phoneNumber: String
    let code: String
}

nonisolated struct EmailVerificationCodeRequestDTO: Encodable, Sendable {
    let email: String
}

nonisolated struct EmailVerificationRequestDTO: Encodable, Sendable {
    let email: String
    let code: String
}

nonisolated struct TermsAgreementRequestDTO: Encodable, Sendable {
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
}

nonisolated struct AuthOnboardingRequestDTO: Encodable, Sendable {
    let firstName: String
    let lastName: String
    let gender: String
    let birthDate: String
    let country: String
    let occupation: String
    let email: String
    let visaType: String
}

nonisolated struct LandlordOnboardingRequestDTO: Encodable, Sendable {
    let name: String
    let phoneNumber: String
}
