//
//  LifeTipInterface.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

import ComposableArchitecture

// MARK: - Interface

protocol LifeTipInterface {
    func fetchTopics() async throws -> [LivingGuide]
    func fetchTips(topicCode: String) async throws -> [LivingGuideTip]
}

// MARK: - Client

struct LifeTipClient: Sendable {
    var fetchTopics: @Sendable () async throws -> [LivingGuide]
    var fetchTips: @Sendable (_ topicCode: String) async throws -> [LivingGuideTip]
}

extension LifeTipClient {
    init(repository: any LifeTipInterface) {
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
    var lifeTipClient: LifeTipClient {
        get { self[LifeTipClient.self] }
        set { self[LifeTipClient.self] = newValue }
    }
}
