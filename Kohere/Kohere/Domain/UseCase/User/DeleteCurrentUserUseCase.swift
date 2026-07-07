//
//  DeleteCurrentUserUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct DeleteCurrentUserUseCase {
    var execute: () async throws -> Void
}

extension DeleteCurrentUserUseCase: DependencyKey {
    static let liveValue: DeleteCurrentUserUseCase = {
        @Dependency(\.userClient)
        var userClient

        return DeleteCurrentUserUseCase {
            try await userClient.deleteCurrentUser()
        }
    }()
}

extension DependencyValues {
    var deleteCurrentUserUseCase: DeleteCurrentUserUseCase {
        get { self[DeleteCurrentUserUseCase.self] }
        set { self[DeleteCurrentUserUseCase.self] = newValue }
    }
}
