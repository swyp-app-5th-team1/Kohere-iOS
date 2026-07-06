//
//  DiagnosisInterface.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

protocol DiagnosisInterface {
    func fetchQuestion(step: Int) async throws -> Diagnosis
    func saveAnswer(_ answer: DiagnosisAnswer) async throws
    func submit() async throws -> DiagnosisSubmission
	func fetchDetail(diagnosisID: Int) async throws -> DiagnosisDetail
    func fetchRecommendations(diagnosisID: Int) async throws -> DiagnosisRecommendations
}

struct DiagnosisClient: Sendable {
    var fetchQuestion: @Sendable (_ step: Int) async throws -> Diagnosis
    var saveAnswer: @Sendable (_ answer: DiagnosisAnswer) async throws -> Void
    var submit: @Sendable () async throws -> DiagnosisSubmission
	var fetchDetail: @Sendable (_ diagnosisID: Int) async throws -> DiagnosisDetail
    var fetchRecommendations: @Sendable (_ diagnosisID: Int) async throws -> DiagnosisRecommendations
}

extension DiagnosisClient {
    init(repository: any DiagnosisInterface) {
        self.init(
            fetchQuestion: { step in
                try await repository.fetchQuestion(step: step)
            },
            saveAnswer: { answer in
                try await repository.saveAnswer(answer)
            },
            submit: {
                try await repository.submit()
			},
            fetchDetail: { diagnosisID in
                try await repository.fetchDetail(diagnosisID: diagnosisID)
            },
            fetchRecommendations: { diagnosisID in
                try await repository.fetchRecommendations(diagnosisID: diagnosisID)
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
