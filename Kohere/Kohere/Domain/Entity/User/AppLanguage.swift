//
//  AppLanguage.swift
//  Kohere
//
//  Created by Codex on 7/18/26.
//

import Foundation

enum AppLanguage: String, CaseIterable, Codable, Equatable, Sendable {
    case korean = "ko"
    case english = "en"

    static var systemDefault: Self {
        Bundle.main.preferredLocalizations.first?.hasPrefix("ko") == true
            ? .korean
            : .english
    }

    nonisolated var locale: Locale {
        Locale(identifier: rawValue)
    }

    nonisolated init(locale: Locale) {
        self = locale.language.languageCode?.identifier == Self.korean.rawValue
            ? .korean
            : .english
    }

    nonisolated func localized(_ key: String, fallback: String? = nil) -> String {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main.localizedString(
                forKey: key,
                value: fallback ?? key,
                table: nil
            )
        }

        return bundle.localizedString(
            forKey: key,
            value: fallback ?? key,
            table: nil
        )
    }

    var title: String {
        switch self {
        case .korean:
            "한국어"
        case .english:
            "English"
        }
    }
}
