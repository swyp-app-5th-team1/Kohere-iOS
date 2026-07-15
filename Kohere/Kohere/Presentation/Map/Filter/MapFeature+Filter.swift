//
//  MapFeature+Filter.swift
//  Kohere
//
//  Created by Codex on 7/15/26.
//

import ComposableArchitecture

extension MapFeature {
    func handleFilterApplyButtonTapped(state: inout State) -> Effect<Action> {
        let previousAppliedFilter = state.appliedFilter
        state.appliedFilter = state.editingFilter

        if state.appliedFilterSource != .diagnosis || state.appliedFilter != previousAppliedFilter {
            state.appliedFilterSource = .manual
        }

        state.isDiagnosisMatchesButtonExpanded = true
        state.isFilterPresented = false
        return beginLocationSearch(.filterApplied, state: &state)
    }
}
