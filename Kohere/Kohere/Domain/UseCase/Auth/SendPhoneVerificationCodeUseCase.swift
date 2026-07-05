//
//  SendPhoneVerificationCodeUseCase.swift
//  Kohere
//
//  Created by mandoo on 7/3/26.
//

import ComposableArchitecture

struct SendPhoneVerificationCodeUseCase {
    var execute: (_ phoneNumber: String) async throws -> PhoneVerificationCode
}

extension SendPhoneVerificationCodeUseCase: DependencyKey {
    static let liveValue: SendPhoneVerificationCodeUseCase = {
        @Dependency(\.authClient)
        var authClient

        return SendPhoneVerificationCodeUseCase { phoneNumber in
            try await authClient.sendPhoneVerificationCode(phoneNumber)
        }
    }()
}

extension DependencyValues {
    var sendPhoneVerificationCodeUseCase: SendPhoneVerificationCodeUseCase {
        get { self[SendPhoneVerificationCodeUseCase.self] }
        set { self[SendPhoneVerificationCodeUseCase.self] = newValue }
    }
}
