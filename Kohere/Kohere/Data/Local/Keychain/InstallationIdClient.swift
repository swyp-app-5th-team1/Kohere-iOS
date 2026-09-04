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
/// Keychain 읽기·저장에 실패하면 새 값을 만들지 않고 에러를 던진다 — 영속되지 않은 ID는 서버에 등록하지 않는다.
struct InstallationIdClient: Sendable {
    var id: @Sendable () throws -> String
}

extension InstallationIdClient: DependencyKey {
    static let liveValue: InstallationIdClient = {
        let provider = InstallationIdProvider()
        return InstallationIdClient(id: { try provider.id() })
    }()
}

extension DependencyValues {
    var installationIdClient: InstallationIdClient {
        get { self[InstallationIdClient.self] }
        set { self[InstallationIdClient.self] = newValue }
    }
}

nonisolated private final class InstallationIdProvider: Sendable {
    private let keychainClient: KeychainClient
    private let cached = OSAllocatedUnfairLock<String?>(initialState: nil)

    init(keychainClient: KeychainClient = .liveValue) {
        self.keychainClient = keychainClient
    }

    func id() throws -> String {
        try cached.withLock { cached in
            if let cached { return cached }

            let identifier = try loadOrCreate()
            cached = identifier   // 영속에 성공한 값만 캐시한다. 실패한 시도는 흔적을 남기지 않아 다음 호출이 재시도한다.
            return identifier
        }
    }

    /// 항목이 없을 때(errSecItemNotFound)만 새 UUID를 생성한다.
    /// 읽기 실패·디코딩 실패·저장 실패는 모두 전파해, 기존 ID가 있는데 새 ID를 만들어 서버에 중복 행을 남기는 일을 막는다.
    private func loadOrCreate() throws -> String {
        if let stored = try keychainClient.load(for: .installationId),
           stored.isEmpty == false {
            return stored
        }

        let identifier = UUID().uuidString.lowercased()
        try keychainClient.save(identifier, for: .installationId)

        return identifier
    }
}
