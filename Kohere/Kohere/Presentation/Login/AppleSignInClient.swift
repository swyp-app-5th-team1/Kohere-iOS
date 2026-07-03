//
//  AppleSignInClient.swift
//  Kohere
//
//  Created by Codex on 7/1/26.
//

import AuthenticationServices
import ComposableArchitecture
import UIKit

struct AppleSignInResult: Equatable, Sendable {
    let idToken: String
    let authorizationCode: String?
}

struct AppleSignInClient {
    var signIn: @MainActor () async throws -> AppleSignInResult
}

extension AppleSignInClient: DependencyKey {
    static let liveValue = AppleSignInClient {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let credential = try await AppleSignInCoordinator().signIn(request: request)

        guard
            let identityToken = credential.identityToken,
            let idToken = String(data: identityToken, encoding: .utf8)
        else {
            throw DataError.underlying(message: "Apple idToken을 가져오지 못했습니다.")
        }

        let authorizationCode = credential.authorizationCode
            .flatMap { String(data: $0, encoding: .utf8) }

        return AppleSignInResult(
            idToken: idToken,
            authorizationCode: authorizationCode
        )
    }
}

extension DependencyValues {
    var appleSignInClient: AppleSignInClient {
        get { self[AppleSignInClient.self] }
        set { self[AppleSignInClient.self] = newValue }
    }
}

@MainActor
private final class AppleSignInCoordinator: NSObject {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func signIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(
                throwing: DataError.underlying(message: "Apple 로그인 인증 정보를 가져오지 못했습니다.")
            )
            continuation = nil
            return
        }

        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.kohereKeyWindow ?? ASPresentationAnchor()
    }
}

private extension UIApplication {
    var kohereKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
