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
        @Dependency(\.keychainClient)
        var keychainClient

        return SubmitDiagnosisUseCase {
            let auth = try keychainClient.load(for: .auth)
            guard let accessToken = auth?.accessToken else {
                throw DataError.serverError(code: "UNAUTHENTICATED", message: "인증이 필요합니다.")
            }

            return try await diagnosisClient.submit(accessToken)
        }
    }()
}

extension DependencyValues {
    var submitDiagnosisUseCase: SubmitDiagnosisUseCase {
        get { self[SubmitDiagnosisUseCase.self] }
        set { self[SubmitDiagnosisUseCase.self] = newValue }
    }
}
