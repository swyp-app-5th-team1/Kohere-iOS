//
//  Quiz.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

struct Quiz: Equatable, Identifiable {
    let id: Int
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
}

extension Quiz {
    enum OptionResultState {
        case normal
        case correct
        case wrong
        case unselected
    }
    
    func resultState(for index: Int, selected: Int?) -> OptionResultState {
        guard let selectedIndex = selected else { return .normal }
        if index == correctAnswerIndex { return .correct }
        if index == selectedIndex { return .wrong }
        return .unselected
    }
}

extension Quiz {
    static let mockQuiz = Quiz(
        id: 1,
        question: "What’s usually NOT covered by Goshiwon maintenance fees?",
        options: [
            "Internet & Wi-Fi",
            "Personal Electricity Bill",
            "Cleaning of common areas",
            "Water Bill"
        ],
        correctAnswerIndex: 1
    )
}
