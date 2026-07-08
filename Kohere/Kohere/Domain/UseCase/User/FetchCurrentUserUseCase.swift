//
//  FetchCurrentUserUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct FetchCurrentUserUseCase {
    var execute: () async throws -> UserProfile
}

extension FetchCurrentUserUseCase: DependencyKey {
    static let liveValue: FetchCurrentUserUseCase = {
        @Dependency(\.userClient)
        var userClient

        return FetchCurrentUserUseCase {
            try await userClient.fetchCurrentUser()
        }
    }()
}

extension DependencyValues {
    var fetchCurrentUserUseCase: FetchCurrentUserUseCase {
        get { self[FetchCurrentUserUseCase.self] }
        set { self[FetchCurrentUserUseCase.self] = newValue }
    }
}
