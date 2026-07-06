//
//  Diagnosis.swift
//  Kohere
//
//  Created by mandoo on 6/26/26.
//

enum SelectType: Equatable {
    case single
    case multi
    case slider
}

struct Diagnosis: Equatable {
    let step: Int
    let field: String
    let question: String
    let selectType: SelectType
    let maxSelectCount: Int
    let options: [DiagnosisOption]
}

struct DiagnosisOption: Equatable {
    let id: String
    let title: String
}
