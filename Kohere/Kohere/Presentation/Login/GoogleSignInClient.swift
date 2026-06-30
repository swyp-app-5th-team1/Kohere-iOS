//
//  GoogleSignInClient.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import ComposableArchitecture
import GoogleSignIn
import UIKit

struct GoogleSignInClient {
    var signIn: @MainActor () async throws -> String
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

        let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SERVER_CLIENT_ID") as? String
        let normalizedServerClientID = serverClientID.flatMap { value -> String? in
            guard !value.isEmpty, value != "$(GOOGLE_SERVER_CLIENT_ID)" else { return nil }
            return value
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: normalizedServerClientID
        )

        guard let presentingViewController = UIApplication.shared.kohereRootViewController else {
            throw DataError.underlying(message: "Google 로그인 화면을 표시할 수 없습니다.")
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw DataError.underlying(message: "Google idToken을 가져오지 못했습니다.")
        }

        return idToken
    }
}

extension DependencyValues {
    var googleSignInClient: GoogleSignInClient {
        get { self[GoogleSignInClient.self] }
        set { self[GoogleSignInClient.self] = newValue }
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
