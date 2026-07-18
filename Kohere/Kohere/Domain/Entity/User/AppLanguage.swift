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

    var locale: Locale {
        Locale(identifier: rawValue)
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
