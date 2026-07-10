//
//  RootFeature+Auth.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import Foundation

extension RootFeature {
    static let startupRefreshBuffer: TimeInterval = 60

    static func resolveStoredAuth(
        _ auth: Auth?,
        keychainClient: KeychainClient,
        reissueToken: (_ refreshToken: String) async throws -> AuthToken
    ) async -> Auth? {
        guard let auth else { return nil }

        guard auth.shouldRefresh(buffer: startupRefreshBuffer) else {
            return auth
        }

        guard let refreshToken = auth.refreshToken, !refreshToken.isEmpty else {
            try? keychainClient.delete(for: .auth)
            return nil
        }

        do {
            let token = try await reissueToken(refreshToken)
            let updatedAuth = auth.updating(with: token)

            do {
                try keychainClient.save(updatedAuth, for: .auth)
            } catch {
                return auth
            }

            return updatedAuth
        } catch {
            if isInvalidRefreshTokenError(error) {
                try? keychainClient.delete(for: .auth)
                return nil
            }

            return auth
        }
    }

    private static func isInvalidRefreshTokenError(_ error: Error) -> Bool {
        guard let dataError = error as? DataError else { return false }

        switch dataError {
        case let .httpStatus(code, _):
            return code == 401

        case let .serverError(code, _):
            return invalidRefreshTokenServerCodes.contains(code)

        default:
            return false
        }
    }

    private static let invalidRefreshTokenServerCodes: Set<String> = [
        "UNAUTHENTICATED",
        "TOKEN_EXPIRED",
        "INVALID_REFRESH_TOKEN",
        "REFRESH_TOKEN_EXPIRED"
    ]
}
