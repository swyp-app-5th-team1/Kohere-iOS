//
//  FetchLivingGuideTopicsUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct FetchLivingGuideTopicsUseCase: Sendable {
    var execute: @Sendable () async throws -> [LivingGuide]
}

extension FetchLivingGuideTopicsUseCase: DependencyKey {
    static let liveValue: FetchLivingGuideTopicsUseCase = {
        @Dependency(\.livingGuideClient)
        var livingGuideClient

        return FetchLivingGuideTopicsUseCase {
            try await livingGuideClient.fetchTopics()
        }
    }()
}

extension DependencyValues {
    var fetchLivingGuideTopicsUseCase: FetchLivingGuideTopicsUseCase {
        get { self[FetchLivingGuideTopicsUseCase.self] }
        set { self[FetchLivingGuideTopicsUseCase.self] = newValue }
    }
}
