//
//  FetchDiagnosisQuestionUseCase.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

struct FetchDiagnosisQuestionUseCase {
    var execute: (_ step: Int) async throws -> Diagnosis
}

extension FetchDiagnosisQuestionUseCase: DependencyKey {
    static let liveValue: FetchDiagnosisQuestionUseCase = {
        @Dependency(\.diagnosisClient)
        var diagnosisClient

        return FetchDiagnosisQuestionUseCase { step in
            try await diagnosisClient.fetchQuestion(step)
        }
    }()
}

extension DependencyValues {
    var fetchDiagnosisQuestionUseCase: FetchDiagnosisQuestionUseCase {
        get { self[FetchDiagnosisQuestionUseCase.self] }
        set { self[FetchDiagnosisQuestionUseCase.self] = newValue }
    }
}
