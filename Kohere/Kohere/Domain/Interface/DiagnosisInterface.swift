//
//  DiagnosisInterface.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

protocol DiagnosisInterface {
    func fetchDetail(diagnosisID: Int) async throws -> DiagnosisDetail
    func fetchRecommendations(diagnosisID: Int) async throws -> DiagnosisRecommendations
}

struct DiagnosisClient: Sendable {
    var fetchDetail: @Sendable (_ diagnosisID: Int) async throws -> DiagnosisDetail
    var fetchRecommendations: @Sendable (_ diagnosisID: Int) async throws -> DiagnosisRecommendations
}

extension DiagnosisClient {
    init(repository: any DiagnosisInterface) {
        self.init(
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
