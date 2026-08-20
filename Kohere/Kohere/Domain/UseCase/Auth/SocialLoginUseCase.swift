//
//  SocialLoginUseCase.swift
//  Kohere
//
//  Created by soomin on 6/30/26.
//

import ComposableArchitecture

struct SocialLoginUseCase {
    var execute: (_ credential: SocialLoginCredential) async throws -> Auth
}

extension SocialLoginUseCase: DependencyKey {
    static let liveValue: SocialLoginUseCase = {
        @Dependency(\.authClient)
        var authClient
        
        return SocialLoginUseCase { credential in
            try await authClient.socialLogin(credential)
        }
    }()
}

extension DependencyValues {
    var socialLoginUseCase: SocialLoginUseCase {
        get { self[SocialLoginUseCase.self] }
        set { self[SocialLoginUseCase.self] = newValue }
    }
}
