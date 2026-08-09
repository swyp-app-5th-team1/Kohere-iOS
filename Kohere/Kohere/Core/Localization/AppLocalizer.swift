//
//  AppLocalizer.swift
//  Kohere
//
//  Created by soomin on 8/9/26.
//

import Foundation

nonisolated enum AppLocalizer {
    nonisolated static func resolve(_ resource: LocalizedStringResource, language: AppLanguage) -> String {
        var resource = resource
        resource.locale = language.locale
        return String(localized: resource)
    }

    nonisolated static func resolve(key: String, language: AppLanguage, fallback: String? = nil) -> String {
        guard let path = Bundle.main.path(forResource: language.apiCode, ofType: "lproj"), let bundle = Bundle(path: path) else {
            return Bundle.main.localizedString(forKey: key, value: fallback ?? key, table: nil)
        }

        return bundle.localizedString(forKey: key, value: fallback ?? key, table: nil)
    }
}

extension AppLanguage {
    nonisolated func localized(_ resource: LocalizedStringResource) -> String {
        AppLocalizer.resolve(resource, language: self)
    }

    nonisolated func localizedString(forKey key: String, fallback: String? = nil) -> String {
        AppLocalizer.resolve(key: key, language: self, fallback: fallback)
    }
}
