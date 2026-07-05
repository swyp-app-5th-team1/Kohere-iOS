//
//  SettingsClient.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture
import UIKit

struct SettingsClient {
    var openApplicationSettings: @Sendable () async -> Void
}

extension SettingsClient: DependencyKey {
    static let liveValue = SettingsClient(
        openApplicationSettings: {
            await MainActor.run {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        }
    )
}

extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}
