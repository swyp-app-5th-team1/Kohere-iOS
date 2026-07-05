//
//  DiagnosisResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

struct DiagnosisQuestionResponseDTO: Decodable {
    let step: Int
    let field: String
    let question: String
    let select: DiagnosisSelectResponseDTO
    let options: [DiagnosisOptionResponseDTO]
}

struct DiagnosisSelectResponseDTO: Decodable {
    let type: String
    let max: Int?
}

struct DiagnosisOptionResponseDTO: Decodable {
    let code: String
    let label: String
}

struct DiagnosisSubmissionResponseDTO: Decodable {
    let diagnosisId: Int
    let status: String
    let submittedAt: String?
}
