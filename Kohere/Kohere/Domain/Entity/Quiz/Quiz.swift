//
//  Quiz.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

struct Quiz: Equatable, Identifiable {
    let id: Int
    let question: String
    let choices: [QuizChoice]
    let correctChoiceKey: String?
    let explanation: String?
}

struct QuizChoice: Equatable, Identifiable {
    nonisolated var id: String { key }

    let key: String
    let text: String
}

struct QuizAnswerResult: Equatable {
    let quizID: Int
    let selectedChoiceKey: String
    let isCorrect: Bool
    let correctChoiceKey: String
    let explanation: String
}

extension Quiz {
    static let mockQuiz = Quiz(
        id: 1,
        question: "What’s usually NOT covered by Goshiwon maintenance fees?",
        choices: [
            QuizChoice(key: "A", text: "Internet & Wi-Fi"),
            QuizChoice(key: "B", text: "Personal Electricity Bill"),
            QuizChoice(key: "C", text: "Cleaning of common areas"),
            QuizChoice(key: "D", text: "Water Bill")
        ],
        correctChoiceKey: "B",
        explanation: "Electricity bills are usually charged separately based on how much you use in your own room."
    )
}
