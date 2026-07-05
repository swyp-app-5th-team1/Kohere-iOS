//
//  DiagnosisInterface.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

protocol DiagnosisInterface {
    func fetchQuestion(step: Int, accessToken: String) async throws -> Diagnosis
    func saveAnswer(_ answer: DiagnosisAnswer, accessToken: String) async throws
    func submit(accessToken: String) async throws -> DiagnosisSubmission
}

struct DiagnosisClient: Sendable {
    var fetchQuestion: @Sendable (_ step: Int, _ accessToken: String) async throws -> Diagnosis
    var saveAnswer: @Sendable (_ answer: DiagnosisAnswer, _ accessToken: String) async throws -> Void
    var submit: @Sendable (_ accessToken: String) async throws -> DiagnosisSubmission
}

extension DiagnosisClient {
    init(repository: any DiagnosisInterface) {
        self.init(
            fetchQuestion: { step, accessToken in
                try await repository.fetchQuestion(step: step, accessToken: accessToken)
            },
            saveAnswer: { answer, accessToken in
                try await repository.saveAnswer(answer, accessToken: accessToken)
            },
            submit: { accessToken in
                try await repository.submit(accessToken: accessToken)
            }
        )
    }
}

extension DependencyValues {
    var diagnosisClient: DiagnosisClient {
        get { self[DiagnosisClient.self] }
        set { self[DiagnosisClient.self] = newValue }
    }
}
