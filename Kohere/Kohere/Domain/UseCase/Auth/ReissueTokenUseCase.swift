//
//  ReissueTokenUseCase.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

struct ReissueTokenUseCase {
    var execute: (_ refreshToken: String) async throws -> AuthToken
}

extension ReissueTokenUseCase: DependencyKey {
    static let liveValue: ReissueTokenUseCase = {
        @Dependency(\.authClient)
        var authClient
        
        return ReissueTokenUseCase { refreshToken in
            try await authClient.reissue(refreshToken)
        }
    }()
}

extension DependencyValues {
    var reissueTokenUseCase: ReissueTokenUseCase {
        get { self[ReissueTokenUseCase.self] }
        set { self[ReissueTokenUseCase.self] = newValue }
    }
}
