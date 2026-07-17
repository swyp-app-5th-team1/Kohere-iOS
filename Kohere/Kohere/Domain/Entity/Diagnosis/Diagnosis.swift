//
//  Diagnosis.swift
//  Kohere
//
//  Created by mandoo on 6/26/26.
//

enum SelectType: Equatable, Sendable {
    case single
    case multi
    case slider
}

struct Diagnosis: Equatable, Sendable {
    let step: Int
    let field: String
    let question: String
    let selectType: SelectType
    let maxSelectCount: Int
    let options: [DiagnosisOption]
}

struct DiagnosisOption: Equatable, Sendable {
    let id: String
    let title: String
}

enum DiagnosisFlowResult: Equatable, Sendable {
    case nextQuestion(Diagnosis)
    case restart
    case terminated
    case completed(diagnosisID: String)
}
