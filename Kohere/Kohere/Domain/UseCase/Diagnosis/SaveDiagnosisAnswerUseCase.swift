//
//  SaveDiagnosisAnswerUseCase.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

struct SaveDiagnosisAnswerUseCase {
    var execute: (_ answer: DiagnosisAnswer) async throws -> Void
}

extension SaveDiagnosisAnswerUseCase: DependencyKey {
    static let liveValue: SaveDiagnosisAnswerUseCase = {
        @Dependency(\.diagnosisClient)
        var diagnosisClient

        return SaveDiagnosisAnswerUseCase { answer in
            try await diagnosisClient.saveAnswer(answer)
        }
    }()
}

extension DependencyValues {
    var saveDiagnosisAnswerUseCase: SaveDiagnosisAnswerUseCase {
        get { self[SaveDiagnosisAnswerUseCase.self] }
        set { self[SaveDiagnosisAnswerUseCase.self] = newValue }
    }
}
