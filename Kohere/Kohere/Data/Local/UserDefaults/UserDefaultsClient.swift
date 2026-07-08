//
//  UserDefaultsClient.swift
//  Kohere
//
//  Created by Codex on 7/3/26.
//

import ComposableArchitecture
import Foundation

enum UserDefaultsClientError: Error, Sendable {
    case typeMismatch(key: String)
}

struct UserDefaultsKey<Value: Codable & Sendable>: Sendable {
    let rawValue: String
}

extension UserDefaultsKey where Value == Bool {
    nonisolated static let hasLaunchedBefore = Self(rawValue: "hasLaunchedBefore")
}

extension UserDefaultsKey where Value == Date {
    nonisolated static let mapDiagnosisButtonLastExpandedAt = Self(rawValue: "mapDiagnosisButtonLastExpandedAt")
}

extension UserDefaultsKey where Value == [String] {
    nonisolated static let recentSearchKeywords = Self(rawValue: "recentSearchKeywords")
}

enum UserDefaultsStoredValue: Sendable {
    case bool(Bool)
    case integer(Int)
    case double(Double)
    case float(Float)
    case string(String)
    case date(Date)
    case data(Data)
    case unsupported(String)
}

struct UserDefaultsClient: Sendable {
    var saveValue: @Sendable (_ value: UserDefaultsStoredValue, _ key: String) -> Void
    var loadValue: @Sendable (_ key: String) -> UserDefaultsStoredValue?
    var delete: @Sendable (_ key: String) -> Void
}

extension UserDefaultsClient {
    nonisolated func save<Value: Codable & Sendable>(
        _ value: Value,
        for key: UserDefaultsKey<Value>
    ) throws {
        if let storedValue = UserDefaultsStoredValue(value) {
            saveValue(storedValue, key.rawValue)
            return
        }
        
        let data = try JSONEncoder().encode(value)
        saveValue(.data(data), key.rawValue)
    }

    nonisolated func load<Value: Codable & Sendable>(
        for key: UserDefaultsKey<Value>
    ) throws -> Value? {
        guard let storedValue = loadValue(key.rawValue) else { return nil }
        
        if let value = storedValue.value(as: Value.self) {
            return value
        }
        
        guard case let .data(data) = storedValue else {
            throw UserDefaultsClientError.typeMismatch(key: key.rawValue)
        }
        
        return try JSONDecoder().decode(Value.self, from: data)
    }
}

extension UserDefaultsStoredValue {
    nonisolated init?<Value>(_ value: Value) {
        switch value {
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .integer(value)
        case let value as Double:
            self = .double(value)
        case let value as Float:
            self = .float(value)
        case let value as String:
            self = .string(value)
        case let value as Date:
            self = .date(value)
        case let value as Data:
            self = .data(value)
        default:
            return nil
        }
    }
    
    nonisolated init(object: Any) {
        switch object {
        case let value as String:
            self = .string(value)
        case let value as Date:
            self = .date(value)
        case let value as Data:
            self = .data(value)
        case let value as NSNumber:
            self = Self.numberValue(value)
        default:
            self = .unsupported(String(describing: Swift.type(of: object)))
        }
    }
    
    nonisolated func value<Value>(as type: Value.Type) -> Value? {
        switch self {
        case let .bool(value):
            return value as? Value
        case let .integer(value):
            return value as? Value
        case let .double(value):
            return value as? Value
        case let .float(value):
            return value as? Value
        case let .string(value):
            return value as? Value
        case let .date(value):
            return value as? Value
        case let .data(value):
            return value as? Value
        case .unsupported:
            return nil
        }
    }
    
    private nonisolated static func numberValue(_ number: NSNumber) -> UserDefaultsStoredValue {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return .bool(number.boolValue)
        }
        
        switch String(cString: number.objCType) {
        case "f":
            return .float(number.floatValue)
        case "d":
            return .double(number.doubleValue)
        default:
            return .integer(Int(truncating: number))
        }
    }
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        saveValue: { value, key in
            switch value {
            case let .bool(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .integer(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .double(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .float(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .string(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .date(value):
                UserDefaults.standard.set(value, forKey: key)
            case let .data(value):
                UserDefaults.standard.set(value, forKey: key)
            case .unsupported:
                assertionFailure("Unsupported UserDefaults value cannot be saved.")
            }
        },
        loadValue: { key in
            guard let object = UserDefaults.standard.object(forKey: key) else {
                return nil
            }
            
            return UserDefaultsStoredValue(object: object)
        },
        delete: { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    )
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
