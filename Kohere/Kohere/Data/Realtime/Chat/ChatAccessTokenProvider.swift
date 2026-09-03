//
//  ChatAccessTokenProvider.swift
//  Kohere
//
//  Created by soomin on 8/28/26.
//

import Foundation

struct ChatAccessTokenProvider: Sendable {
    private let keychainClient: KeychainClient
    private let reissueToken: @Sendable (_ refreshToken: String) async throws -> AuthToken

    init(
        keychainClient: KeychainClient = .liveValue,
        reissueToken: @escaping @Sendable (_ refreshToken: String) async throws -> AuthToken = {
            try await ReissueTokenUseCase.liveValue.execute($0)
        }
    ) {
        self.keychainClient = keychainClient
        self.reissueToken = reissueToken
    }

    func validAccessToken() async throws -> String {
        guard let auth = try keychainClient.load(for: .auth), !auth.accessToken.isEmpty else {
            throw ChatRealtimeError.missingAccessToken
        }
        guard auth.shouldRefresh() else { return auth.accessToken }
        guard let refreshToken = auth.refreshToken, !refreshToken.isEmpty else {
            expireSession(reason: .missingRefreshToken)
            throw ChatAccessTokenError.missingRefreshToken
        }

        do {
            let token = try await reissueToken(refreshToken)
            let updatedAuth = auth.updating(with: token)
            try keychainClient.save(updatedAuth, for: .auth)
            return updatedAuth.accessToken
        } catch {
            guard !Self.shouldPreserveSession(for: error) else { throw error }
            expireSession(reason: Self.expirationReason(for: error))
            throw error
        }
    }

    private func expireSession(reason: AuthSessionExpirationReason) {
        try? keychainClient.delete(for: .auth)
        let context = AuthSessionExpirationContext(
            reason: reason,
            attemptID: String(UUID().uuidString.prefix(8)),
            requestPath: "/ws/chat"
        )
        Task { @MainActor in
            NotificationCenter.default.post(name: .authSessionExpired, object: context)
        }
    }

    private static func shouldPreserveSession(for error: Error) -> Bool {
        guard let dataError = error as? DataError, case .transport = dataError else { return false }
        return true
    }

    private static func expirationReason(for error: Error) -> AuthSessionExpirationReason {
        if error is KeychainError { return .keychainFailure }
        guard let dataError = error as? DataError else { return .unknownRefreshFailure }
        if dataError.invalidatesRefreshToken { return .refreshUnauthorized }
        switch dataError {
        case let .httpStatus(code, _):
            return code == 401 ? .refreshUnauthorized : .refreshHTTPFailure
        case .serverError:
            return .refreshServerFailure
        case .decodingFailed, .emptyResponse:
            return .refreshDecodingFailure
        case .transport:
            return .refreshTransportFailure
        default:
            return .unknownRefreshFailure
        }
    }
}

enum ChatAccessTokenError: Error {
    case missingRefreshToken
}
