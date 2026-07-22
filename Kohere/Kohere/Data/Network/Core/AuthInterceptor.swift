//
//  AuthInterceptor.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation
import OSLog

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.kohere.Kohere",
        category: "AuthRefresh"
    )

    private let keychainClient: KeychainClient
    private let reissueToken: @Sendable (_ refreshToken: String) async throws -> AuthToken
    private let refreshManager: RefreshTokenManager
    
    init(
        keychainClient: KeychainClient = .liveValue,
        refreshManager: RefreshTokenManager,
        reissueToken: @escaping @Sendable (_ refreshToken: String) async throws -> AuthToken = {
            try await ReissueTokenUseCase.liveValue.execute($0)
        }
    ) {
        self.keychainClient = keychainClient
        self.refreshManager = refreshManager
        self.reissueToken = reissueToken
    }
    
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        var request = urlRequest
        let path = requestPath(request)
        
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            log("event=adapt_skipped reason=authorization_already_set path=\(path)")
            completion(.success(request))
            return
        }
        
        if isAuthRequest(request) {
            log("event=adapt_skipped reason=auth_endpoint path=\(path)")
            completion(.success(request))
            return
        }
        
        do {
            guard let auth = try keychainClient.load(for: .auth) else {
                log("event=adapt_skipped reason=missing_auth path=\(path)")
                completion(.success(request))
                return
            }
            
            let tokenType = auth.tokenType.isEmpty ? "Bearer" : auth.tokenType
            request.setValue(
                "\(tokenType) \(auth.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
            log("event=authorization_attached path=\(path)")
            
            completion(.success(request))
        } catch {
            log(
                "event=adapt_failed path=\(path) category=\(failureCategory(for: error))"
            )
            completion(.failure(error))
        }
    }
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401,
              !isAuthRequest(request.request)
        else {
            completion(.doNotRetryWithError(error))
            return
        }

        guard request.request?.value(forHTTPHeaderField: "Authorization") != nil else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        guard request.retryCount == 0 else {
            let attemptID = String(UUID().uuidString.prefix(8))
            let path = requestPath(request.request)
            log(
                "event=retry_unauthorized attemptID=\(attemptID) path=\(path) retryCount=\(request.retryCount) decision=expire_session"
            )
            completion(.doNotRetryWithError(error))
            notifySessionExpired(
                reason: .retryUnauthorized,
                attemptID: attemptID,
                requestPath: path
            )
            return
        }
        
        Task {
            let path = requestPath(request.request)
            let decision = await refreshManager.enqueue(completion)
            let attemptID = decision.attemptID
            
            guard decision.shouldStartRefresh else {
                log(
                    "event=refresh_waiting attemptID=\(attemptID) path=\(path) retryCount=\(request.retryCount)"
                )
                return
            }
            
            var stage = AuthRefreshStage.loadStoredAuth

            do {
                log(
                    "event=refresh_started attemptID=\(attemptID) path=\(path) retryCount=\(request.retryCount)"
                )
                let currentAuth = try loadRefreshableAuth()
                log(
                    "event=refresh_credential_loaded attemptID=\(attemptID) hasRefreshToken=true"
                )
                
                stage = .requestReissue
                let startedAt = ContinuousClock.now
                let refreshedToken = try await reissueToken(currentAuth.refreshToken)
                let updatedAuth = merge(currentAuth.auth, with: refreshedToken)
                let elapsed = startedAt.duration(to: .now)
                
                stage = .saveUpdatedAuth
                try keychainClient.save(updatedAuth, for: .auth)
                log(
                    "event=refresh_succeeded attemptID=\(attemptID) expiresIn=\(refreshedToken.expiresIn) elapsed=\(elapsed) decision=retry_requests"
                )
                await refreshManager.complete(with: .retry)
            } catch {
                let category = failureCategory(for: error)

                if Self.shouldPreserveAuthAfterRefreshFailure(error) {
                    log(
                        "event=refresh_failed attemptID=\(attemptID) path=\(path) stage=\(stage.rawValue) category=\(category) authDeleted=false decision=preserve_auth"
                    )
                    await refreshManager.complete(with: .doNotRetryWithError(error))
                    return
                }

                let reason = sessionExpirationReason(
                    for: error,
                    stage: stage
                )
                let didDeleteAuth: Bool

                do {
                    try keychainClient.delete(for: .auth)
                    didDeleteAuth = true
                } catch {
                    didDeleteAuth = false
                    log(
                        "event=auth_delete_failed attemptID=\(attemptID) category=\(failureCategory(for: error))"
                    )
                }

                log(
                    "event=refresh_failed attemptID=\(attemptID) path=\(path) stage=\(stage.rawValue) category=\(category) authDeleted=\(didDeleteAuth) decision=expire_session"
                )
                await refreshManager.complete(with: .doNotRetryWithError(error))
                notifySessionExpired(
                    reason: reason,
                    attemptID: attemptID,
                    requestPath: path
                )
            }
        }
    }
    
    private func isAuthRequest(_ request: URLRequest?) -> Bool {
        guard let path = request?.url?.path else { return false }
        
        return path.contains("/api/v1/auth/social-login")
            || path.contains("/api/v1/auth/reissue")
    }
    
    private func loadRefreshableAuth() throws -> RefreshableAuth {
        guard let auth = try keychainClient.load(for: .auth),
              let refreshToken = auth.refreshToken
        else {
            throw AuthInterceptorError.missingRefreshToken
        }
        
        return RefreshableAuth(auth: auth, refreshToken: refreshToken)
    }
    
    private func merge(_ auth: Auth, with token: AuthToken) -> Auth {
        auth.updating(with: token)
    }
    
    private func notifySessionExpired(
        reason: AuthSessionExpirationReason,
        attemptID: String,
        requestPath: String
    ) {
        let context = AuthSessionExpirationContext(
            reason: reason,
            attemptID: attemptID,
            requestPath: requestPath
        )

        log(
            "event=session_expired attemptID=\(attemptID) path=\(requestPath) reason=\(reason.rawValue)"
        )

        Task { @MainActor in
            NotificationCenter.default.post(
                name: .authSessionExpired,
                object: context
            )
        }
    }
    
    private func requestPath(_ request: URLRequest?) -> String {
        request?.url?.path ?? "unknown"
    }
    
    private func sessionExpirationReason(
        for error: Error,
        stage: AuthRefreshStage
    ) -> AuthSessionExpirationReason {
        if error is KeychainError {
            return .keychainFailure
        }

        if error is AuthInterceptorError {
            return .missingRefreshToken
        }

        guard let dataError = error as? DataError else {
            return .unknownRefreshFailure
        }

        if dataError.invalidatesRefreshToken {
            return .refreshUnauthorized
        }

        switch dataError {
        case let .httpStatus(code, _):
            return code == 401 ? .refreshUnauthorized : .refreshHTTPFailure

        case .serverError:
            return .refreshServerFailure

        case .decodingFailed, .emptyResponse:
            return .refreshDecodingFailure

        case .transport:
            return .refreshTransportFailure

        case .underlying:
            return .unknownRefreshFailure

        default:
            return stage == .saveUpdatedAuth ? .keychainFailure : .unknownRefreshFailure
        }
    }

    private func failureCategory(for error: Error) -> String {
        if error is KeychainError { return "keychain" }
        if error is AuthInterceptorError { return "missing_refresh_token" }

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

    nonisolated static func shouldPreserveAuthAfterRefreshFailure(_ error: Error) -> Bool {
        guard let dataError = error as? DataError else { return false }
        guard case .transport = dataError else { return false }
        return true
    }

    private func log(_ message: String) {
        Self.logger.info("\(message, privacy: .public)")
    }
}

private struct RefreshableAuth {
    let auth: Auth
    let refreshToken: String
}

private enum AuthInterceptorError: Error {
    case missingRefreshToken
}

private enum AuthRefreshStage: String {
    case loadStoredAuth = "load_stored_auth"
    case requestReissue = "request_reissue"
    case saveUpdatedAuth = "save_updated_auth"
}

enum AuthSessionExpirationReason: String, Sendable {
    case retryUnauthorized = "retry_unauthorized"
    case missingRefreshToken = "missing_refresh_token"
    case refreshUnauthorized = "refresh_unauthorized"
    case refreshHTTPFailure = "refresh_http_failure"
    case refreshServerFailure = "refresh_server_failure"
    case refreshDecodingFailure = "refresh_decoding_failure"
    case refreshTransportFailure = "refresh_transport_failure"
    case keychainFailure = "keychain_failure"
    case unknownRefreshFailure = "unknown_refresh_failure"
}

struct AuthSessionExpirationContext: Sendable {
    let reason: AuthSessionExpirationReason
    let attemptID: String
    let requestPath: String
}

extension Notification.Name {
    nonisolated static let authSessionExpired = Notification.Name("authSessionExpired")
}
