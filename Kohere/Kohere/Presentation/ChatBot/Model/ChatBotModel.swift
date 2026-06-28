//
//  SelectionType.swift
//  Kohere
//
//  Created by mandoo on 6/26/26.
//

enum SelectionType: Equatable {
    case single
    case multi(max: Int)
}

struct ChatBotQuestion: Equatable, Identifiable {
    var id: Int { step }
    
    let step: Int
    let field: String
    let questionText: String
    let selectionType: SelectionType
    let options: [ChatBotOption]
}

struct ChatBotOption: Equatable, Identifiable {
    var id: String { code }
    
    let code: String
    let label: String
}
