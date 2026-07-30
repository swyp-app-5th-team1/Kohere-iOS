//
//  AuthRequestDTO.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

nonisolated enum SocialLoginRequestDTO: Encodable, Sendable {
    case google(idToken: String, email: String?, name: String?)
    case apple(authorizationCode: String, email: String?, name: String?)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .google(idToken, email, name):
            try container.encode("GOOGLE", forKey: .provider)
            try container.encode(idToken, forKey: .idToken)
            try container.encodeIfPresent(email, forKey: .email)
            try container.encodeIfPresent(name, forKey: .name)

        case let .apple(authorizationCode, email, name):
            try container.encode("APPLE", forKey: .provider)
            try container.encode(authorizationCode, forKey: .authorizationCode)
            try container.encodeIfPresent(email, forKey: .email)
            try container.encodeIfPresent(name, forKey: .name)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case provider
        case idToken
        case authorizationCode
        case email
        case name
    }
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
    let gender: String
    let birthDate: String
    let country: String
    let visaType: String
    let lang: String
}

nonisolated struct LandlordOnboardingRequestDTO: Encodable, Sendable {
    let phoneNumber: String
    let birthDate: String
}
