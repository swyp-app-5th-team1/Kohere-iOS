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
    var saveAuth: @Sendable (_ auth: Auth) async throws -> Void
    var loadAuth: @Sendable () async throws -> Auth?
    var deleteAuth: @Sendable () async throws -> Void
}

extension KeychainClient: DependencyKey {
    static let liveValue: KeychainClient = {
        let store = KeychainAuthStore()
        
        return KeychainClient(
            saveAuth: { auth in
                try await store.save(auth)
            },
            loadAuth: {
                try await store.load()
            },
            deleteAuth: {
                try await store.delete()
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

private final class KeychainAuthStore: @unchecked Sendable {
    private let service: String
    private let account = "auth"
    
    init(service: String = Bundle.main.bundleIdentifier ?? "com.kohere.auth") {
        self.service = service
    }
    
    func save(_ auth: Auth) throws {
        guard let data = try? JSONEncoder().encode(auth) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
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
    
    func load() throws -> Auth? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
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
        
        guard let data = item as? Data,
              let auth = try? JSONDecoder().decode(Auth.self, from: data) else {
            throw KeychainError.decodingFailed
        }
        
        return auth
    }
    
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }
}
