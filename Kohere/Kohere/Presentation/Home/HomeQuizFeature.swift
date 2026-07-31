//
//  HomeQuizFeature.swift
//  Kohere
//
//  Created by Codex on 7/31/26.
//

import ComposableArchitecture
import Foundation

private extension HomeQuizFeature {
    enum EffectID {
        static let quiz = "HomeFeature.quiz"
        static let answer = "HomeFeature.quizAnswer"
    }
}

@Reducer
struct HomeQuizFeature {
    @Dependency(\.quizClient)
    var quizClient

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var quiz: QuizModel
        var isLoading = false
        var isLoaded = false
        var isAnswerSubmitting = false
        var errorMessage: String?

        init(quiz: Quiz = Quiz.mockQuiz) {
            self.quiz = QuizModel(entity: quiz, selectedChoiceKey: nil)
        }
    }

    // MARK: - Action
    
    enum Action {
        case onAppear
        case cancelEffects
        case randomQuizResponse(Result<Quiz, DataError>)
        case optionTapped(index: Int)
        case answerResponse(Result<QuizAnswerResult, DataError>)
    }
    
    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading, !state.isLoaded else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { [quizClient] send in
                    do {
                        let quiz = try await quizClient.fetchRandomQuiz()
                        await send(.randomQuizResponse(.success(quiz)))
                    } catch {
                        await send(.randomQuizResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: EffectID.quiz, cancelInFlight: true)

            case .cancelEffects:
                return .merge(
                    .cancel(id: EffectID.quiz),
                    .cancel(id: EffectID.answer)
                )

            case let .randomQuizResponse(.success(quiz)):
                state.quiz = QuizModel(entity: quiz)
                state.isLoading = false
                state.isLoaded = true
                state.errorMessage = nil
                return .none

            case let .randomQuizResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .optionTapped(index):
                guard state.isLoaded,
                      !state.quiz.hasAnswered,
                      !state.isAnswerSubmitting,
                      let selectedChoiceKey = state.quiz.choiceKey(for: index)
                else { return .none }

                state.quiz.selectedChoiceKey = selectedChoiceKey
                state.isAnswerSubmitting = true
                state.errorMessage = nil

                return .run { [quizClient, quizID = state.quiz.id] send in
                    do {
                        let result = try await quizClient.submitAnswer(quizID, selectedChoiceKey)
                        await send(.answerResponse(.success(result)))
                    } catch {
                        await send(.answerResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: EffectID.answer, cancelInFlight: true)

            case let .answerResponse(.success(result)):
                state.quiz.apply(answerResult: result)
                state.isAnswerSubmitting = false
                state.errorMessage = nil
                return .none

            case let .answerResponse(.failure(error)):
                state.quiz.selectedChoiceKey = nil
                state.isAnswerSubmitting = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
