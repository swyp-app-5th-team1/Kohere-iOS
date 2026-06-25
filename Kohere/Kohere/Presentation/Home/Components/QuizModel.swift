//
//  QuizModel.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

import SwiftUI

struct QuizModel: Equatable {
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    var selectedAnswerIndex: Int?
    var hasAnswered: Bool { selectedAnswerIndex != nil }
    
    init(entity: Quiz, selectedAnswerIndex: Int? = nil) {
        self.question = entity.question
        self.options = entity.options
        self.correctAnswerIndex = entity.correctAnswerIndex
        self.selectedAnswerIndex = selectedAnswerIndex
    }
    
    func optionStyle(for index: Int) -> UIStyle {
        guard let selectedIndex = selectedAnswerIndex else {
            return UIStyle(textColor: .labelNeutral, tintColor: .clear, backgroundColor: .backgroundNormalNormal, iconName: nil)
        }
        
        if index == correctAnswerIndex {
            return UIStyle(textColor: .statusGreen70, tintColor: .statusPositive, backgroundColor: .statusGreen5, iconName: "check_16")
        }
        
        if index == selectedIndex {
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
