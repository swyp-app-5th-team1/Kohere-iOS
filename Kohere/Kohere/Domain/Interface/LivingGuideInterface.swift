//
//  LivingGuideInterface.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

import ComposableArchitecture

// MARK: - Interface

protocol LivingGuideInterface {
    func fetchTopics() async throws -> [LivingGuide]
    func fetchTips(topicCode: String) async throws -> [LivingGuideTip]
}

// MARK: - Client

struct LivingGuideClient: Sendable {
    var fetchTopics: @Sendable () async throws -> [LivingGuide]
    var fetchTips: @Sendable (_ topicCode: String) async throws -> [LivingGuideTip]
}

extension LivingGuideClient {
    init(repository: any LivingGuideInterface) {
        self.init(
            fetchTopics: {
                try await repository.fetchTopics()
            },
            fetchTips: { topicCode in
                try await repository.fetchTips(topicCode: topicCode)
            }
        )
    }
}

// MARK: - Dependency

extension DependencyValues {
    var livingGuideClient: LivingGuideClient {
        get { self[LivingGuideClient.self] }
        set { self[LivingGuideClient.self] = newValue }
    }
}
