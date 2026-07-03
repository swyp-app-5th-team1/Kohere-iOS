//
//  SocialLoginUseCase.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

struct SocialLoginUseCase {
    var execute: (_ credential: SocialLoginCredential) async throws -> Auth
}

extension SocialLoginUseCase: DependencyKey {
    static let liveValue = SocialLoginUseCase { credential in
        try await AuthRepository().socialLogin(credential: credential)
    }
}

extension DependencyValues {
    var socialLoginUseCase: SocialLoginUseCase {
        get { self[SocialLoginUseCase.self] }
        set { self[SocialLoginUseCase.self] = newValue }
    }
}
