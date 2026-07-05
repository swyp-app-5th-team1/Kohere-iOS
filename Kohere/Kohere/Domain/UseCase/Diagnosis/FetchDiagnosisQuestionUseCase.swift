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
        @Dependency(\.keychainClient)
        var keychainClient

        return FetchDiagnosisQuestionUseCase { step in
            let auth = try keychainClient.load(for: .auth)
            guard let accessToken = auth?.accessToken else {
                throw DataError.serverError(code: "UNAUTHENTICATED", message: "인증이 필요합니다.")
            }

            return try await diagnosisClient.fetchQuestion(step, accessToken)
        }
    }()
}

extension DependencyValues {
    var fetchDiagnosisQuestionUseCase: FetchDiagnosisQuestionUseCase {
        get { self[FetchDiagnosisQuestionUseCase.self] }
        set { self[FetchDiagnosisQuestionUseCase.self] = newValue }
    }
}
