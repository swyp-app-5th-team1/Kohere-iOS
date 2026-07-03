//
//  AuthRequestDTO.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

nonisolated enum SocialLoginRequestDTO: Encodable, Sendable {
    case google(idToken: String)
    case apple(authorizationCode: String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .google(idToken):
            try container.encode("GOOGLE", forKey: .provider)
            try container.encode(idToken, forKey: .idToken)

        case let .apple(authorizationCode):
            try container.encode("APPLE", forKey: .provider)
            try container.encode(authorizationCode, forKey: .authorizationCode)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case provider
        case idToken
        case authorizationCode
    }
}

nonisolated struct ReissueTokenRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

nonisolated struct LogoutRequestDTO: Encodable, Sendable {
    let refreshToken: String
}
