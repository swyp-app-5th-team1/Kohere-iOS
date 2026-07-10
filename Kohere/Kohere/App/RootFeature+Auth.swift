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
            try keychainClient.save(updatedAuth, for: .auth)
            return updatedAuth
        } catch {
            try? keychainClient.delete(for: .auth)
            return nil
        }
    }
}
