//
//  FetchRandomQuizUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct FetchRandomQuizUseCase: Sendable {
    var execute: @Sendable () async throws -> Quiz
}

extension FetchRandomQuizUseCase: DependencyKey {
    static let liveValue: FetchRandomQuizUseCase = {
        @Dependency(\.quizClient)
        var quizClient

        return FetchRandomQuizUseCase {
            try await quizClient.fetchRandomQuiz()
        }
    }()
}

extension DependencyValues {
    var fetchRandomQuizUseCase: FetchRandomQuizUseCase {
        get { self[FetchRandomQuizUseCase.self] }
        set { self[FetchRandomQuizUseCase.self] = newValue }
    }
}
