//
//  DiagnosisRequestDTO.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

nonisolated struct DiagnosisRecommendationsQueryDTO: Encodable {
    let page: Int?
    let size: Int?
    let sort: String?
}
