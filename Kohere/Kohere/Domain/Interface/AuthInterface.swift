//
//  AuthInterface.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

protocol AuthInterface {
    func socialLogin(credential: SocialLoginCredential) async throws -> Auth
    func reissue(refreshToken: String) async throws -> AuthToken
    func logout(accessToken: String, refreshToken: String) async throws
}

struct AuthClient: Sendable {
    var socialLogin: @Sendable (_ credential: SocialLoginCredential) async throws -> Auth
    var reissue: @Sendable (_ refreshToken: String) async throws -> AuthToken
    var logout: @Sendable (_ accessToken: String, _ refreshToken: String) async throws -> Void
}

extension AuthClient {
    init(repository: any AuthInterface) {
        self.init(
            socialLogin: { credential in
                try await repository.socialLogin(credential: credential)
            },
            reissue: { refreshToken in
                try await repository.reissue(refreshToken: refreshToken)
            },
            logout: { accessToken, refreshToken in
                try await repository.logout(
                    accessToken: accessToken,
                    refreshToken: refreshToken
                )
            }
        )
    }
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
