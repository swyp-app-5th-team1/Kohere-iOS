//
//  SocialLoginUseCase.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

struct SocialLoginUseCase {
    var execute: (_ provider: SocialLoginProvider, _ idToken: String) async throws -> Auth
}

extension SocialLoginUseCase: DependencyKey {
    static let liveValue = SocialLoginUseCase { provider, idToken in
        try await AuthRepository().socialLogin(provider: provider, idToken: idToken)
    }
}

extension DependencyValues {
    var socialLoginUseCase: SocialLoginUseCase {
        get { self[SocialLoginUseCase.self] }
        set { self[SocialLoginUseCase.self] = newValue }
    }
}
