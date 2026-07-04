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
    func logout() async throws
}

struct AuthClient: Sendable {
    var socialLogin: @Sendable (_ credential: SocialLoginCredential) async throws -> Auth
    var reissue: @Sendable (_ refreshToken: String) async throws -> AuthToken
    var logout: @Sendable () async throws -> Void
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
            logout: {
                try await repository.logout()
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
