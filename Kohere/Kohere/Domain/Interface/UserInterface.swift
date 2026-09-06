//
//  UserInterface.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

protocol UserInterface {
    func fetchCurrentUser() async throws -> UserProfile
    func fetchChatPushEnabled() async throws -> Bool
    func updateChatPushEnabled(_ isEnabled: Bool) async throws -> Bool
    func updateProfile(_ update: UserProfileUpdate) async throws -> UserProfile
    func deleteCurrentUser() async throws
}

struct UserClient: Sendable {
    var fetchCurrentUser: @Sendable () async throws -> UserProfile
    var fetchChatPushEnabled: @Sendable () async throws -> Bool
    var updateChatPushEnabled: @Sendable (_ isEnabled: Bool) async throws -> Bool
    var updateProfile: @Sendable (_ update: UserProfileUpdate) async throws -> UserProfile
    var deleteCurrentUser: @Sendable () async throws -> Void
}

extension UserClient {
    init(repository: any UserInterface) {
        self.init(
            fetchCurrentUser: {
                try await repository.fetchCurrentUser()
            },
            fetchChatPushEnabled: {
                try await repository.fetchChatPushEnabled()
            },
            updateChatPushEnabled: { isEnabled in
                try await repository.updateChatPushEnabled(isEnabled)
            },
            updateProfile: { update in
                try await repository.updateProfile(update)
            },
            deleteCurrentUser: {
                try await repository.deleteCurrentUser()
            }
        )
    }
}

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}
