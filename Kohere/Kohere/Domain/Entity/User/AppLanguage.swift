//
//  AppLanguage.swift
//  Kohere
//
//  Created by soomin on 8/9/26.
//

import Foundation

nonisolated enum AppLanguage: CaseIterable, Codable, Equatable, Sendable {
    case korean
    case english

    var apiCode: String {
        switch self {
        case .korean:
            "ko"
        case .english:
            "en"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .korean:
            "ko-KR"
        case .english:
            "en-US"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var nativeDisplayName: String {
        switch self {
        case .korean:
            "한국어"
        case .english:
            "English"
        }
    }

    init?(apiCode: String) {
        switch apiCode.lowercased() {
        case "ko":
            self = .korean
        case "en":
            self = .english
        default:
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let apiCode = try container.decode(String.self)

        guard let language = Self(apiCode: apiCode) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported app language code: \(apiCode)")
        }

        self = language
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiCode)
    }
}
