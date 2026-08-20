//
//  QuizResponseDTO.swift
//  Kohere
//
//  Created by soomin on 7/7/26.
//

struct QuizRandomResponseDTO: Decodable {
    let quizId: Int?
    let question: String?
    let choices: [QuizChoiceResponseDTO]?
}

struct QuizChoiceResponseDTO: Decodable {
    let key: String?
    let text: String?
}

struct QuizAnswerResponseDTO: Decodable {
    let quizId: Int?
    let selectedChoice: String?
    let correct: Bool?
    let correctChoice: String?
    let explanation: String?
}
