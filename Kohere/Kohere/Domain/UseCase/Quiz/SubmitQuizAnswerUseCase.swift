//
//  SubmitQuizAnswerUseCase.swift
//  Kohere
//
//  Created by soomin on 9/22/26.
//

import ComposableArchitecture

struct SubmitQuizAnswerUseCase: Sendable {
    var execute: @Sendable (_ quizID: Int, _ selectedChoiceKey: String) async throws -> QuizAnswerResult
}

extension SubmitQuizAnswerUseCase: DependencyKey {
    static let liveValue: SubmitQuizAnswerUseCase = {
        @Dependency(\.quizClient)
        var quizClient

        return SubmitQuizAnswerUseCase { quizID, selectedChoiceKey in
            try await quizClient.submitAnswer(quizID, selectedChoiceKey)
        }
    }()
}

extension DependencyValues {
    var submitQuizAnswerUseCase: SubmitQuizAnswerUseCase {
        get { self[SubmitQuizAnswerUseCase.self] }
        set { self[SubmitQuizAnswerUseCase.self] = newValue }
    }
}
