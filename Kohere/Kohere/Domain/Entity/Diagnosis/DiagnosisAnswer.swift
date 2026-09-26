//
//  DiagnosisAnswer.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

enum DiagnosisAnswer: Equatable, Sendable {
    case single(field: String, code: String)
    case multiple(field: String, codes: [String])
    case monthlyRent(field: String, min: Int, max: Int)
}
