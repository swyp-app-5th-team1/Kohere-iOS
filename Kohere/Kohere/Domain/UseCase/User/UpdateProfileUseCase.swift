//
//  UpdateProfileUseCase.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

struct UpdateProfileUseCase {
    var execute: (_ update: UserProfileUpdate) async throws -> UserProfile
}

extension UpdateProfileUseCase: DependencyKey {
    static let liveValue: UpdateProfileUseCase = {
        @Dependency(\.userClient)
        var userClient

        return UpdateProfileUseCase { update in
            try await userClient.updateProfile(update)
        }
    }()
}

extension DependencyValues {
    var updateProfileUseCase: UpdateProfileUseCase {
        get { self[UpdateProfileUseCase.self] }
        set { self[UpdateProfileUseCase.self] = newValue }
    }
}
