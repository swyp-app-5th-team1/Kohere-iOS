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
        @Dependency(\.keychainClient)
        var keychainClient

        return SaveDiagnosisAnswerUseCase { answer in
            let auth = try keychainClient.load(for: .auth)
            guard let accessToken = auth?.accessToken else {
                throw DataError.serverError(code: "UNAUTHENTICATED", message: "인증이 필요합니다.")
            }

            try await diagnosisClient.saveAnswer(answer, accessToken)
        }
    }()
}

extension DependencyValues {
    var saveDiagnosisAnswerUseCase: SaveDiagnosisAnswerUseCase {
        get { self[SaveDiagnosisAnswerUseCase.self] }
        set { self[SaveDiagnosisAnswerUseCase.self] = newValue }
    }
}
