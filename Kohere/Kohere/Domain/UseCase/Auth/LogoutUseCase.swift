//
//  LogoutUseCase.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

enum LogoutError: Error {
    case remoteRequestFailed
    case localAuthCleanupFailed
}

struct LogoutUseCase {
    var execute: () async throws -> Void
}

extension LogoutUseCase: DependencyKey {
    static let liveValue: LogoutUseCase = {
        @Dependency(\.authClient)
        var authClient
        
        return LogoutUseCase {
            try await authClient.logout()
        }
    }()
}

extension DependencyValues {
    var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}
