//
//  SendEmailVerificationCodeUseCase.swift
//  Kohere
//
//  Created by mandoo on 7/3/26.
//

import ComposableArchitecture

struct SendEmailVerificationCodeUseCase {
    var execute: (_ email: String) async throws -> EmailVerificationCode
}

extension SendEmailVerificationCodeUseCase: DependencyKey {
    static let liveValue: SendEmailVerificationCodeUseCase = {
        @Dependency(\.authClient)
        var authClient

        return SendEmailVerificationCodeUseCase { email in
            try await authClient.sendEmailVerificationCode(email)
        }
    }()
}

extension DependencyValues {
    var sendEmailVerificationCodeUseCase: SendEmailVerificationCodeUseCase {
        get { self[SendEmailVerificationCodeUseCase.self] }
        set { self[SendEmailVerificationCodeUseCase.self] = newValue }
    }
}
