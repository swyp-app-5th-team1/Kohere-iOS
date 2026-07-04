//
//  LogoutUseCase.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

struct LogoutUseCase {
    var execute: (_ accessToken: String, _ refreshToken: String) async throws -> Void
}

extension LogoutUseCase: DependencyKey {
    static let liveValue: LogoutUseCase = {
        @Dependency(\.authClient)
        var authClient
        
        return LogoutUseCase { accessToken, refreshToken in
            try await authClient.logout(accessToken, refreshToken)
        }
    }()
}

extension DependencyValues {
    var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}
