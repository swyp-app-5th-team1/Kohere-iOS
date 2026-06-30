//
//  AuthResponseDTO.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

struct SocialLoginResponseDTO: Decodable {
    let onboardingRequired: Bool
    let status: String
    let tokenType: String
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    func toEntity() -> Auth {
        Auth(
            onboardingRequired: onboardingRequired,
            status: AuthStatus(rawValue: status) ?? .unknown,
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

struct TokenResponseDTO: Decodable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    func toEntity() -> AuthToken {
        AuthToken(
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}
