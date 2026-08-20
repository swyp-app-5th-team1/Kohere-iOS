//
//  QuizRepository.swift
//  Kohere
//
//  Created by soomin on 7/7/26.
//

import ComposableArchitecture

// MARK: - Repository

final class QuizRepository: QuizInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchRandomQuiz() async throws -> Quiz {
        let environment = try environmentProvider()
        let responseDTO: QuizRandomResponseDTO = try await authenticatedNetworkService.request(
            QuizRouter.random(environment)
        )

        return try responseDTO.toEntity()
    }

    func submitAnswer(quizID: Int, selectedChoiceKey: String) async throws -> QuizAnswerResult {
        let environment = try environmentProvider()
        let requestDTO = QuizAnswerRequestDTO(selectedChoice: selectedChoiceKey)
        let responseDTO: QuizAnswerResponseDTO = try await authenticatedNetworkService.request(
            QuizRouter.answer(quizID: quizID, requestDTO: requestDTO, environment)
        )

        return try responseDTO.toEntity()
    }
}

// MARK: - Dependency

extension QuizClient: DependencyKey {
    static let liveValue: QuizClient = {
        let repository: any QuizInterface = QuizRepository()
        return QuizClient(repository: repository)
    }()
}

// MARK: - Mapper

private extension QuizRandomResponseDTO {
    func toEntity() throws -> Quiz {
        guard let quizId, let question else {
            throw DataError.decodingFailed
        }

        return Quiz(
            id: quizId,
            question: question,
            choices: (choices ?? []).compactMap { $0.toEntity() },
            correctChoiceKey: nil,
            explanation: nil
        )
    }
}

private extension QuizChoiceResponseDTO {
    func toEntity() -> QuizChoice? {
        guard let key, let text else { return nil }
        return QuizChoice(key: key, text: text)
    }
}

extension QuizAnswerResponseDTO {
    func toEntity() throws -> QuizAnswerResult {
        guard let quizId, let selectedChoice, let correct else {
            throw DataError.decodingFailed
        }

        let resolvedCorrectChoice: String
        if let correctChoice {
            resolvedCorrectChoice = correctChoice
        } else if correct {
            resolvedCorrectChoice = selectedChoice
        } else {
            throw DataError.decodingFailed
        }

        return QuizAnswerResult(
            quizID: quizId,
            selectedChoiceKey: selectedChoice,
            isCorrect: correct,
            correctChoiceKey: resolvedCorrectChoice,
            explanation: explanation ?? ""
        )
    }
}
