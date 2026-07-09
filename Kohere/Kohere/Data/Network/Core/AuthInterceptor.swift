//
//  AuthInterceptor.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
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
            debugLog("adapt skipped. authorization already set. path=\(path)")
            completion(.success(request))
            return
        }
        
        if isAuthRequest(request) {
            debugLog("adapt skipped. auth endpoint. path=\(path)")
            completion(.success(request))
            return
        }
        
        do {
            guard let auth = try keychainClient.load(for: .auth) else {
                debugLog("adapt skipped. no auth in keychain. authorization not attached. path=\(path)")
                completion(.success(request))
                return
            }
            
            let tokenType = auth.tokenType.isEmpty ? "Bearer" : auth.tokenType
            request.setValue(
                "\(tokenType) \(auth.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
            debugLog("adapt attached authorization. path=\(path), accessToken=\(maskedToken(auth.accessToken))")
            
            completion(.success(request))
        } catch {
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
        
        guard request.retryCount == 0 else {
            debugLog("retry already attempted. session will expire. path=\(requestPath(request.request))")
            completion(.doNotRetryWithError(error))
            notifySessionExpired()
            return
        }
        
        Task {
            let shouldRefresh = await refreshManager.enqueue(completion)
            
            guard shouldRefresh else {
                debugLog("refresh already in progress. request is waiting. path=\(requestPath(request.request))")
                return
            }
            
            do {
                debugLog("refresh started. originalPath=\(requestPath(request.request))")
                let currentAuth = try loadRefreshableAuth()
                debugLog("refresh token loaded. refreshToken=\(maskedToken(currentAuth.refreshToken))")
                
                let refreshedToken = try await reissueToken(currentAuth.refreshToken)
                let updatedAuth = merge(currentAuth.auth, with: refreshedToken)
                
                try keychainClient.save(updatedAuth, for: .auth)
                debugLog(
                    """
                    refresh succeeded. accessToken=\(maskedToken(refreshedToken.accessToken)), \
                    refreshToken=\(maskedToken(refreshedToken.refreshToken)), expiresIn=\(refreshedToken.expiresIn)
                    """
                )
                await refreshManager.complete(with: .retry)
            } catch {
                try? keychainClient.delete(for: .auth)
                debugLog("refresh failed. error=\(error.localizedDescription). auth removed from keychain.")
                await refreshManager.complete(with: .doNotRetryWithError(error))
                notifySessionExpired()
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
    
    private func notifySessionExpired() {
        Task { @MainActor in
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
        }
    }
    
    private func requestPath(_ request: URLRequest?) -> String {
        request?.url?.path ?? "unknown"
    }
    
    private func maskedToken(_ token: String) -> String {
        guard token.count > 10 else { return "***" }
        
        let prefix = token.prefix(6)
        let suffix = token.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[AuthInterceptor] \(message)")
        #endif
    }
}

private struct RefreshableAuth {
    let auth: Auth
    let refreshToken: String
}

private enum AuthInterceptorError: Error {
    case missingRefreshToken
}

extension Notification.Name {
    nonisolated static let authSessionExpired = Notification.Name("authSessionExpired")
}
