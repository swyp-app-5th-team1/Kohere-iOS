//
//  VerifyEmailUseCase.swift
//  Kohere
//
//  Created by soomin on 7/3/26.
//

import ComposableArchitecture

struct VerifyEmailUseCase {
    var execute: (_ email: String, _ code: String) async throws -> EmailVerification
}

extension VerifyEmailUseCase: DependencyKey {
    static let liveValue: VerifyEmailUseCase = {
        @Dependency(\.authClient)
        var authClient

        return VerifyEmailUseCase { email, code in
            try await authClient.verifyEmail(email, code)
        }
    }()
}

extension DependencyValues {
    var verifyEmailUseCase: VerifyEmailUseCase {
        get { self[VerifyEmailUseCase.self] }
        set { self[VerifyEmailUseCase.self] = newValue }
    }
}
