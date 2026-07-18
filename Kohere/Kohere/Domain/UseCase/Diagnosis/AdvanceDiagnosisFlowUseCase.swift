//
//  AdvanceDiagnosisFlowUseCase.swift
//  Kohere
//
//  Created by soomin on 7/18/26.
//

import ComposableArchitecture

struct AdvanceDiagnosisFlowUseCase {
    var execute: @Sendable (DiagnosisAnswer) async throws -> DiagnosisFlowResult
}

extension AdvanceDiagnosisFlowUseCase: DependencyKey {
    static let liveValue: AdvanceDiagnosisFlowUseCase = {
        @Dependency(\.diagnosisClient)
        var diagnosisClient

        return AdvanceDiagnosisFlowUseCase { answer in
            try await diagnosisClient.advanceFlow(answer)
        }
    }()
}

extension DependencyValues {
    var advanceDiagnosisFlowUseCase: AdvanceDiagnosisFlowUseCase {
        get { self[AdvanceDiagnosisFlowUseCase.self] }
        set { self[AdvanceDiagnosisFlowUseCase.self] = newValue }
    }
}
