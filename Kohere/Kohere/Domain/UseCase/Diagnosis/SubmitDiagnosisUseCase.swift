//
//  SubmitDiagnosisUseCase.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

struct SubmitDiagnosisUseCase {
    var execute: () async throws -> DiagnosisSubmission
}

extension SubmitDiagnosisUseCase: DependencyKey {
    static let liveValue: SubmitDiagnosisUseCase = {
        @Dependency(\.diagnosisClient)
        var diagnosisClient

        return SubmitDiagnosisUseCase {
            try await diagnosisClient.submit()
        }
    }()
}

extension DependencyValues {
    var submitDiagnosisUseCase: SubmitDiagnosisUseCase {
        get { self[SubmitDiagnosisUseCase.self] }
        set { self[SubmitDiagnosisUseCase.self] = newValue }
    }
}
