//
//  Auth.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

struct Auth: Equatable, Codable {
    let onboardingRequired: Bool
    let status: AuthStatus
    let tokenType: String
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
}

struct AuthToken: Equatable, Codable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

enum AuthStatus: String, Equatable, Codable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case unknown
}

enum SocialLoginCredential: Equatable, Sendable {
    case google(idToken: String)
    case apple(authorizationCode: String)
}
