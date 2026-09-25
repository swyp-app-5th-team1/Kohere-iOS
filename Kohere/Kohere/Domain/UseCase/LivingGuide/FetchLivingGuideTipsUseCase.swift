//
//  FetchLivingGuideTipsUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct FetchLivingGuideTipsUseCase: Sendable {
    var execute: @Sendable (_ topicCode: String) async throws -> [LivingGuideTip]
}

extension FetchLivingGuideTipsUseCase: DependencyKey {
    static let liveValue: FetchLivingGuideTipsUseCase = {
        @Dependency(\.livingGuideClient)
        var livingGuideClient

        return FetchLivingGuideTipsUseCase { topicCode in
            try await livingGuideClient.fetchTips(topicCode)
        }
    }()
}

extension DependencyValues {
    var fetchLivingGuideTipsUseCase: FetchLivingGuideTipsUseCase {
        get { self[FetchLivingGuideTipsUseCase.self] }
        set { self[FetchLivingGuideTipsUseCase.self] = newValue }
    }
}
