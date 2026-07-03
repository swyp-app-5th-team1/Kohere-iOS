//
//  KeychainClient.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture
import Foundation
import Security

struct KeychainClient: Sendable {
    var save: @Sendable (_ key: String, _ data: Data) throws -> Void
    var read: @Sendable (_ key: String) throws -> Data?
    var delete: @Sendable (_ key: String) throws -> Void
}

struct KeychainKey<Value: Codable & Sendable>: Sendable {
    let rawValue: String
}

extension KeychainKey where Value == Auth {
    nonisolated static let auth = Self(rawValue: "auth")
}

extension KeychainClient {
    nonisolated func save<Value: Codable & Sendable>(
        _ value: Value,
        for key: KeychainKey<Value>
    ) throws {
        guard let data = try? JSONEncoder().encode(value) else {
            throw KeychainError.encodingFailed
        }
        
        try save(key.rawValue, data)
    }
    
    nonisolated func load<Value: Codable & Sendable>(
        for key: KeychainKey<Value>
    ) throws -> Value? {
        guard let data = try read(key.rawValue) else { return nil }
        
        guard let value = try? JSONDecoder().decode(Value.self, from: data) else {
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    nonisolated func delete<Value: Codable & Sendable>(
        for key: KeychainKey<Value>
    ) throws {
        try delete(key.rawValue)
    }
}

extension KeychainClient: DependencyKey {
    static let liveValue: KeychainClient = {
        let store = KeychainStore()
        
        return KeychainClient(
            save: { key, data in
                try store.save(key: key, data: data)
            },
            read: { key in
                try store.read(key: key)
            },
            delete: { key in
                try store.delete(key: key)
            }
        )
    }()
}

extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}

enum KeychainError: Error, Equatable {
    case encodingFailed
    case decodingFailed
    case unhandledStatus(OSStatus)
}

extension KeychainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            "인증 정보를 저장할 수 없습니다."
            
        case .decodingFailed:
            "저장된 인증 정보를 읽을 수 없습니다."
            
        case let .unhandledStatus(status):
            "키체인 작업이 실패했습니다. status=\(status)"
        }
    }
}

private final class KeychainStore: @unchecked Sendable {
    private let service: String
    
    init(service: String = Bundle.main.bundleIdentifier ?? "com.kohere.Kohere") {
        self.service = service
    }
    
    nonisolated func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            addQuery[kSecValueData as String] = data
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unhandledStatus(updateStatus)
        }
    }
    
    nonisolated func read(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
        
        guard let data = item as? Data else {
            throw KeychainError.decodingFailed
        }
        
        return data
    }
    
    nonisolated func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }
}
