//
//  UserDefaultsClient.swift
//  Kohere
//
//  Created by Codex on 7/3/26.
//

import ComposableArchitecture
import Foundation

enum UserDefaultsKey: String, Sendable {
    case hasLaunchedBefore
}

struct UserDefaultsClient: Sendable {
    var saveData: @Sendable (_ data: Data, _ key: UserDefaultsKey) async -> Void
    var loadData: @Sendable (_ key: UserDefaultsKey) async -> Data?
    var delete: @Sendable (_ key: UserDefaultsKey) async -> Void
}

extension UserDefaultsClient {
    func save<Value: Encodable & Sendable>(
        _ value: Value,
        for key: UserDefaultsKey
    ) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        await saveData(data, key)
    }

    func load<Value: Decodable & Sendable>(
        _ type: Value.Type,
        for key: UserDefaultsKey
    ) async -> Value? {
        guard let data = await loadData(key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        saveData: { data, key in
            UserDefaults.standard.set(data, forKey: key.rawValue)
        },
        loadData: { key in
            UserDefaults.standard.data(forKey: key.rawValue)
        },
        delete: { key in
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    )
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
