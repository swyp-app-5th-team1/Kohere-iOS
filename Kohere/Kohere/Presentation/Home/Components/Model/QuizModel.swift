//
//  QuizModel.swift
//  Kohere
//
//  Created by soomin on 6/25/26.
//

import SwiftUI

struct QuizModel: Equatable {
    let id: Int
    let question: String
    let choices: [QuizChoice]
    var selectedChoiceKey: String?
    var correctChoiceKey: String?
    var explanation: String?
    var options: [String] { choices.map(\.text) }
    var hasAnswered: Bool { selectedChoiceKey != nil && correctChoiceKey != nil }
    var shouldShowExplanation: Bool {
        hasAnswered && !(explanation ?? "").isEmpty
    }
    
    init(entity: Quiz, selectedChoiceKey: String? = nil) {
        self.id = entity.id
        self.question = entity.question
        self.choices = entity.choices
        self.selectedChoiceKey = selectedChoiceKey
        self.correctChoiceKey = entity.correctChoiceKey
        self.explanation = entity.explanation
    }

    func choiceKey(for index: Int) -> String? {
        guard choices.indices.contains(index) else { return nil }
        return choices[index].key
    }

    mutating func apply(answerResult: QuizAnswerResult) {
        selectedChoiceKey = answerResult.selectedChoiceKey
        correctChoiceKey = answerResult.correctChoiceKey
        explanation = answerResult.explanation
    }
    
    func optionStyle(for index: Int) -> UIStyle {
        guard let selectedChoiceKey, let correctChoiceKey, let choiceKey = choiceKey(for: index) else {
            return UIStyle(textColor: .labelNeutral, tintColor: .clear, backgroundColor: .backgroundNormalNormal, iconName: nil)
        }
        
        if choiceKey == correctChoiceKey {
            return UIStyle(textColor: .statusGreen70, tintColor: .statusPositive, backgroundColor: .statusGreen5, iconName: "check_16")
        }
        
        if choiceKey == selectedChoiceKey {
            return UIStyle(textColor: .statusDanger, tintColor: .statusDanger, backgroundColor: .statusRed5, iconName: "close_16")
        }
        
        return UIStyle(textColor: .labelNeutral, tintColor: .clear, backgroundColor: .backgroundNormalNormal, iconName: nil)
    }
    
    struct UIStyle {
        let textColor: Color
        let tintColor: Color
        let backgroundColor: Color
        let iconName: String?
    }
}
