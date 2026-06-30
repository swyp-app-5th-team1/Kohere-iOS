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
    static let liveValue = LogoutUseCase { accessToken, refreshToken in
        try await AuthRepository().logout(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}

extension DependencyValues {
    var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}
