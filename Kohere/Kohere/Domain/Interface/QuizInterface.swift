//
//  QuizInterface.swift
//  Kohere
//
//  Created by mandoo on 7/7/26.
//

import ComposableArchitecture

// MARK: - Interface

protocol QuizInterface {
    func fetchRandomQuiz() async throws -> Quiz
    func submitAnswer(quizID: Int, selectedChoiceKey: String) async throws -> QuizAnswerResult
}

// MARK: - Client

struct QuizClient: Sendable {
    var fetchRandomQuiz: @Sendable () async throws -> Quiz
    var submitAnswer: @Sendable (_ quizID: Int, _ selectedChoiceKey: String) async throws -> QuizAnswerResult
}

extension QuizClient {
    init(repository: any QuizInterface) {
        self.init(
            fetchRandomQuiz: {
                try await repository.fetchRandomQuiz()
            },
            submitAnswer: { quizID, selectedChoiceKey in
                try await repository.submitAnswer(quizID: quizID, selectedChoiceKey: selectedChoiceKey)
            }
        )
    }
}

// MARK: - Dependency

extension DependencyValues {
    var quizClient: QuizClient {
        get { self[QuizClient.self] }
        set { self[QuizClient.self] = newValue }
    }
}
