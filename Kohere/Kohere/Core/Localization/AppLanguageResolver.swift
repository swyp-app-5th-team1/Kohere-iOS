//
//  AppLanguageResolver.swift
//  Kohere
//
//  Created by soomin on 8/9/26.
//

import Foundation

nonisolated enum AppLanguageResolver {
    nonisolated static func resolve(from locale: Locale) -> AppLanguage {
        switch locale.language.languageCode?.identifier {
        case AppLanguage.korean.apiCode:
            .korean
        default:
            .english
        }
    }

    nonisolated static func resolveSystemLanguage(bundle: Bundle = .main) -> AppLanguage {
        guard let preferredLocalization = bundle.preferredLocalizations.first else {
            return .english
        }

        return resolve(from: Locale(identifier: preferredLocalization))
    }
}

extension AppLanguage {
    nonisolated init(locale: Locale) {
        self = AppLanguageResolver.resolve(from: locale)
    }
}
