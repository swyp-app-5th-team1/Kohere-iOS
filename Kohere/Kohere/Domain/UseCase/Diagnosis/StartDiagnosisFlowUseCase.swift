//
//  StartDiagnosisFlowUseCase.swift
//  Kohere
//
//  Created by soomin on 7/18/26.
//

import ComposableArchitecture

struct StartDiagnosisFlowUseCase {
    var execute: @Sendable () async throws -> DiagnosisFlowResult
}

extension StartDiagnosisFlowUseCase: DependencyKey {
    static let liveValue: StartDiagnosisFlowUseCase = {
        @Dependency(\.diagnosisClient)
        var diagnosisClient

        return StartDiagnosisFlowUseCase {
            try await diagnosisClient.startFlow()
        }
    }()
}

extension DependencyValues {
    var startDiagnosisFlowUseCase: StartDiagnosisFlowUseCase {
        get { self[StartDiagnosisFlowUseCase.self] }
        set { self[StartDiagnosisFlowUseCase.self] = newValue }
    }
}
