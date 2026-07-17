//
//  RootFeature+Auth.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import Foundation
import OSLog

private let startupAuthLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.kohere.Kohere",
    category: "StartupAuth"
)

private enum RootAuthLogger {
    nonisolated static let value = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.kohere.Kohere",
        category: "RootAuth"
    )
}

extension RootFeature {
    static let startupRefreshBuffer: TimeInterval = 60

    static func resolveStoredAuth(
        _ auth: Auth?,
        keychainClient: KeychainClient,
        reissueToken: (_ refreshToken: String) async throws -> AuthToken
    ) async -> Auth? {
        let attemptID = String(UUID().uuidString.prefix(8))

        guard let auth else {
            startupAuthLogger.notice(
                "event=startup_auth_resolved attemptID=\(attemptID, privacy: .public) result=missing_auth"
            )
            return nil
        }

        guard auth.shouldRefresh(buffer: startupRefreshBuffer) else {
            startupAuthLogger.info(
                "event=startup_auth_resolved attemptID=\(attemptID, privacy: .public) result=valid_access_token"
            )
            return auth
        }

        guard let refreshToken = auth.refreshToken, !refreshToken.isEmpty else {
            let didDeleteAuth = deleteStoredAuth(
                keychainClient: keychainClient,
                attemptID: attemptID
            )
            startupAuthLogger.notice(
                "event=startup_refresh_failed attemptID=\(attemptID, privacy: .public) category=missing_refresh_token authDeleted=\(didDeleteAuth) decision=route_login"
            )
            return nil
        }

        do {
            startupAuthLogger.info(
                "event=startup_refresh_started attemptID=\(attemptID, privacy: .public) trigger=expiration"
            )
            let token = try await reissueToken(refreshToken)
            let updatedAuth = auth.updating(with: token)

            do {
                try keychainClient.save(updatedAuth, for: .auth)
            } catch {
                let didDeleteAuth = deleteStoredAuth(
                    keychainClient: keychainClient,
                    attemptID: attemptID
                )
                startupAuthLogger.error(
                    "event=startup_refresh_save_failed attemptID=\(attemptID, privacy: .public) category=keychain authDeleted=\(didDeleteAuth) decision=route_login"
                )
                return nil
            }

            startupAuthLogger.info(
                "event=startup_refresh_succeeded attemptID=\(attemptID, privacy: .public) expiresIn=\(token.expiresIn)"
            )
            return updatedAuth
        } catch {
            if let dataError = error as? DataError,
               case .transport = dataError {
                startupAuthLogger.error(
                    "event=startup_refresh_failed attemptID=\(attemptID, privacy: .public) category=\(refreshFailureCategory(error), privacy: .public) authDeleted=false decision=preserve_auth"
                )
                return auth
            }

            let didDeleteAuth = deleteStoredAuth(
                keychainClient: keychainClient,
                attemptID: attemptID
            )
            startupAuthLogger.notice(
                "event=startup_refresh_failed attemptID=\(attemptID, privacy: .public) category=\(refreshFailureCategory(error), privacy: .public) authDeleted=\(didDeleteAuth) decision=route_login"
            )
            return nil
        }
    }

    private static func deleteStoredAuth(
        keychainClient: KeychainClient,
        attemptID: String
    ) -> Bool {
        do {
            try keychainClient.delete(for: .auth)
            return true
        } catch {
            startupAuthLogger.error(
                "event=startup_auth_delete_failed attemptID=\(attemptID, privacy: .public) category=keychain"
            )
            return false
        }
    }

    private static func refreshFailureCategory(_ error: Error) -> String {
        guard let dataError = error as? DataError else { return "unknown" }

        switch dataError {
        case let .httpStatus(code, _):
            return "http_\(code)"
        case let .serverError(code, _):
            return "server_\(code)"
        case .decodingFailed:
            return "decoding"
        case .emptyResponse:
            return "empty_response"
        case .transport:
            return "transport"
        case .underlying:
            return "underlying"
        default:
            return "configuration"
        }
    }

    nonisolated static func startupStorageFailureCategory(_ error: Error) -> String {
        if error is KeychainError { return "keychain" }
        if error is UserDefaultsClientError { return "user_defaults" }
        if error is DecodingError { return "decoding" }
        return "unknown"
    }

    nonisolated static func logFirstLaunchAuthReset() {
        RootAuthLogger.value.notice(
            "event=first_launch_auth_reset decision=delete_stored_auth"
        )
    }

    nonisolated static func logStoredAuthLoaded(_ hasAuth: Bool) {
        RootAuthLogger.value.info("event=stored_auth_loaded hasAuth=\(hasAuth)")
    }

    nonisolated static func logStartupAuthLoadFailure(_ error: Error) {
        RootAuthLogger.value.error(
            "event=startup_auth_load_failed category=\(startupStorageFailureCategory(error), privacy: .public) decision=route_login"
        )
    }

    nonisolated static func logSessionExpiration(
        _ context: AuthSessionExpirationContext?
    ) {
        let attemptID = context?.attemptID ?? "unknown"
        let reason = context?.reason.rawValue ?? "unknown"
        let path = context?.requestPath ?? "unknown"
        RootAuthLogger.value.notice(
            "event=route_login attemptID=\(attemptID, privacy: .public) path=\(path, privacy: .public) reason=\(reason, privacy: .public)"
        )
    }

}
