//
//  HomeQuizFeature.swift
//  Kohere
//
//  Created by soomin on 7/31/26.
//

import ComposableArchitecture
import Foundation

private extension HomeQuizFeature {
    nonisolated enum EffectID: Hashable, Sendable {
        case quiz
        case answer
    }
}

@Reducer
struct HomeQuizFeature {
    @Dependency(\.fetchRandomQuizUseCase)
    var fetchRandomQuiz

    @Dependency(\.submitQuizAnswerUseCase)
    var submitQuizAnswer

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var quiz: Quiz
        var selectedChoiceKey: String?
        var answerResult: QuizAnswerResult?
        var isLoading = false
        var isLoaded = false
        var isAnswerSubmitting = false
        var errorMessage: String?

        var hasAnswered: Bool {
            selectedChoiceKey != nil && correctChoiceKey != nil
        }

        var correctChoiceKey: String? {
            answerResult?.correctChoiceKey ?? quiz.correctChoiceKey
        }

        var explanation: String? {
            answerResult?.explanation ?? quiz.explanation
        }

        var shouldShowExplanation: Bool {
            hasAnswered && !(explanation ?? "").isEmpty
        }

        init(quiz: Quiz = Quiz.mockQuiz) {
            self.quiz = quiz
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
                return .run { [fetchRandomQuiz] send in
                    do {
                        let quiz = try await fetchRandomQuiz.execute()
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
                state.quiz = quiz
                state.selectedChoiceKey = nil
                state.answerResult = nil
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
                      !state.hasAnswered,
                      !state.isAnswerSubmitting,
                      state.quiz.choices.indices.contains(index)
                else { return .none }

                let selectedChoiceKey = state.quiz.choices[index].key
                state.selectedChoiceKey = selectedChoiceKey
                state.isAnswerSubmitting = true
                state.errorMessage = nil

                return .run { [submitQuizAnswer, quizID = state.quiz.id] send in
                    do {
                        let result = try await submitQuizAnswer.execute(quizID, selectedChoiceKey)
                        await send(.answerResponse(.success(result)))
                    } catch {
                        await send(.answerResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: EffectID.answer, cancelInFlight: true)

            case let .answerResponse(.success(result)):
                state.selectedChoiceKey = result.selectedChoiceKey
                state.answerResult = result
                state.isAnswerSubmitting = false
                state.errorMessage = nil
                return .none

            case let .answerResponse(.failure(error)):
                state.selectedChoiceKey = nil
                state.answerResult = nil
                state.isAnswerSubmitting = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
