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
        question: "고시원 계약 시 ‘관리비'에 포함되지 않는 것은?",
        choices: [
            QuizChoice(key: "A", text: "인터넷 & Wi-Fi"),
            QuizChoice(key: "B", text: "개인 전기요금"),
            QuizChoice(key: "C", text: "공용 청소"),
            QuizChoice(key: "D", text: "수도요금")
        ],
        correctChoiceKey: "B",
        explanation: "전기요금은 보통 방 별로 얼마나 썼는지를 기반으로 개별적으로 청구돼요."
    )
}
