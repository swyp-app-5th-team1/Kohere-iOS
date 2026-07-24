//
//  GoogleSignInClient.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import ComposableArchitecture
import GoogleSignIn
import UIKit

struct GoogleSignInResult: Equatable, Sendable {
    let idToken: String
    let email: String?
    let name: String?
}

struct GoogleSignInClient {
    var signIn: @MainActor () async throws -> GoogleSignInResult
}

extension GoogleSignInClient: DependencyKey {
    static let liveValue = GoogleSignInClient {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
            !clientID.isEmpty,
            clientID != "$(GOOGLE_IOS_CLIENT_ID)"
        else {
            throw DataError.underlying(message: "Google iOS Client ID가 설정되지 않았습니다.")
        }
        
        guard
            let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SERVER_CLIENT_ID") as? String,
            !serverClientID.isEmpty,
            serverClientID != "$(GOOGLE_SERVER_CLIENT_ID)"
        else {
            throw DataError.underlying(message: "Google Server Client ID가 설정되지 않았습니다.")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
        
        guard let presentingViewController = UIApplication.shared.kohereRootViewController else {
            throw DataError.underlying(message: "로그인 화면을 표시할 수 없습니다.")
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw DataError.underlying(message: "Google idToken을 가져오지 못했습니다.")
        }

        let profile = result.user.profile
        let name = profile?.name.nilIfBlank
            ?? [profile?.givenName, profile?.familyName]
                .compactMap { $0?.nilIfBlank }
                .joined(separator: " ")
                .nilIfBlank
        
        return GoogleSignInResult(
            idToken: idToken,
            email: profile?.email.nilIfBlank,
            name: name
        )
    }
}

extension DependencyValues {
    var googleSignInClient: GoogleSignInClient {
        get { self[GoogleSignInClient.self] }
        set { self[GoogleSignInClient.self] = newValue }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension UIApplication {
    var kohereRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
