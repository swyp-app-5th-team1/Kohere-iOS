//
//  InstallationIdClient.swift
//  Kohere
//
//  Created by 송규섭 on 9/3/26.
//

import ComposableArchitecture
import Foundation
import os

extension KeychainKey where Value == String {
    nonisolated static let installationId = Self(rawValue: "installationId")
}

/// push-devices API의 경로 파라미터로 쓰는 설치본 UUID.
/// 최초 접근 시 생성해 Keychain에 보관하므로 앱을 삭제 후 재설치해도 같은 값이 유지된다.
struct InstallationIdClient: Sendable {
    var id: @Sendable () -> String
}

extension InstallationIdClient: DependencyKey {
    static let liveValue: InstallationIdClient = {
        let provider = InstallationIdProvider()
        return InstallationIdClient(id: { provider.id() })
    }()
}

extension DependencyValues {
    var installationIdClient: InstallationIdClient {
        get { self[InstallationIdClient.self] }
        set { self[InstallationIdClient.self] = newValue }
    }
}

private final class InstallationIdProvider: Sendable {
    private let keychainClient: KeychainClient
    private let cached = OSAllocatedUnfairLock<String?>(initialState: nil)

    init(keychainClient: KeychainClient = .liveValue) {
        self.keychainClient = keychainClient
    }

    func id() -> String {
        cached.withLock { cached in
            if let cached { return cached }

            let identifier = loadOrCreate()
            cached = identifier
            return identifier
        }
    }

    private func loadOrCreate() -> String {
        if let stored = (try? keychainClient.load(for: .installationId)) ?? nil,
           stored.isEmpty == false {
            return stored
        }

        let identifier = UUID().uuidString.lowercased()

        // 저장에 실패해도 이번 실행 동안은 캐시된 같은 값을 사용한다.
        // 서버의 PUT/DELETE가 멱등이라 다음 실행에서 새 값이 생겨도 동작은 유지된다.
        try? keychainClient.save(identifier, for: .installationId)

        return identifier
    }
}
