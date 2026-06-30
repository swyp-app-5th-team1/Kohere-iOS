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
