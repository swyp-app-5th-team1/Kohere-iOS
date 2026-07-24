//
//  AppleSignInClient.swift
//  Kohere
//
//  Created by Codex on 7/1/26.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation
import UIKit

struct AppleSignInResult: Equatable, Sendable {
    let authorizationCode: String
    let email: String?
    let name: String?
}

struct AppleSignInClient {
    var signIn: @MainActor () async throws -> AppleSignInResult
}

extension AppleSignInClient: DependencyKey {
    static let liveValue = AppleSignInClient {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        guard let window = UIApplication.shared.kohereKeyWindow else {
            throw DataError.underlying(message: "Apple 로그인 화면을 표시할 window를 찾지 못했습니다.")
        }

        let credential = try await AppleSignInCoordinator(presentationAnchor: window).signIn(request: request)

        guard let authorizationCode = credential.authorizationCode
            .flatMap({ String(data: $0, encoding: .utf8) }) else {
            throw DataError.underlying(message: "Apple authorizationCode를 가져오지 못했습니다.")
        }

        let name = Self.formattedName(from: credential.fullName)

        return AppleSignInResult(
            authorizationCode: authorizationCode,
            email: credential.email,
            name: name
        )
    }

    private static func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }

        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long

        let name = formatter.string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? nil : name
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
    private let presentationAnchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    init(presentationAnchor: ASPresentationAnchor) {
        self.presentationAnchor = presentationAnchor
    }

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
        presentationAnchor
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
