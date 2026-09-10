//
//  DiagnosisInterface.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

protocol DiagnosisInterface {
    func startFlow() async throws -> DiagnosisFlowResult
    func advanceFlow(with answer: DiagnosisAnswer) async throws -> DiagnosisFlowResult
    func fetchQuestion(step: Int) async throws -> Diagnosis
    func saveAnswer(_ answer: DiagnosisAnswer) async throws
    func submit() async throws -> DiagnosisSubmission
    func fetchDetail(diagnosisID: Int) async throws -> DiagnosisDetail
    func fetchRecommendations(input: DiagnosisRecommendationsInput) async throws -> DiagnosisRecommendations
    func fetchRecommendationMap(diagnosisID: Int) async throws -> DiagnosisRecommendationMap
}

struct DiagnosisClient: Sendable {
    var startFlow: @Sendable () async throws -> DiagnosisFlowResult
    var advanceFlow: @Sendable (_ answer: DiagnosisAnswer) async throws -> DiagnosisFlowResult
    var fetchQuestion: @Sendable (_ step: Int) async throws -> Diagnosis
    var saveAnswer: @Sendable (_ answer: DiagnosisAnswer) async throws -> Void
    var submit: @Sendable () async throws -> DiagnosisSubmission
    var fetchDetail: @Sendable (_ diagnosisID: Int) async throws -> DiagnosisDetail
    var fetchRecommendations: @MainActor @Sendable (_ input: DiagnosisRecommendationsInput) async throws -> DiagnosisRecommendations
    var fetchRecommendationMap: @MainActor @Sendable (_ diagnosisID: Int) async throws -> DiagnosisRecommendationMap
}

extension DiagnosisClient {
    init(repository: any DiagnosisInterface) {
        self.init(
            startFlow: {
                try await repository.startFlow()
            },
            advanceFlow: { answer in
                try await repository.advanceFlow(with: answer)
            },
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
            fetchRecommendations: { input in
                try await repository.fetchRecommendations(input: input)
            },
            fetchRecommendationMap: { diagnosisID in
                try await repository.fetchRecommendationMap(diagnosisID: diagnosisID)
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
