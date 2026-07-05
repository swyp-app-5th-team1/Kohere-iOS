//
//  MapDiagnosisButtonExpansion.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture
import Foundation

var diagnosisButtonAutoCollapseEffect: Effect<MapFeature.Action> {
    .run { send in
        do {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            await send(.diagnosisButtonAutoCollapseDelayFinished)
        } catch {
            return
        }
    }
    .cancellable(id: "MapFeature.diagnosisButtonAutoCollapse", cancelInFlight: true)
}

func shouldExpandDiagnosisButtonToday(userDefaultsClient: UserDefaultsClient) -> Bool {
    let now = Date()
    let lastExpandedAt = try? userDefaultsClient.load(for: .mapDiagnosisButtonLastExpandedAt)

    if let lastExpandedAt,
       Calendar.current.isDate(lastExpandedAt, inSameDayAs: now) {
        return false
    }

    try? userDefaultsClient.save(now, for: .mapDiagnosisButtonLastExpandedAt)
    return true
}
