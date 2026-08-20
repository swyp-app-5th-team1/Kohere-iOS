//
//  VerifyPhoneUseCase.swift
//  Kohere
//
//  Created by soomin on 7/3/26.
//

import ComposableArchitecture

struct VerifyPhoneUseCase {
    var execute: (_ phoneNumber: String, _ code: String) async throws -> PhoneVerification
}

extension VerifyPhoneUseCase: DependencyKey {
    static let liveValue: VerifyPhoneUseCase = {
        @Dependency(\.authClient)
        var authClient

        return VerifyPhoneUseCase { phoneNumber, code in
            try await authClient.verifyPhone(phoneNumber, code)
        }
    }()
}

extension DependencyValues {
    var verifyPhoneUseCase: VerifyPhoneUseCase {
        get { self[VerifyPhoneUseCase.self] }
        set { self[VerifyPhoneUseCase.self] = newValue }
    }
}
