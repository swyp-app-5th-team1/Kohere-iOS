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

struct DiagnosisFlowResponseDTO: Decodable {
    let resultCode: String
    let question: DiagnosisQuestionResponseDTO?
    let diagnosisId: Int?
    let guestSessionId: String?
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

struct DiagnosisDetailResponseDTO: Decodable {
    let diagnosisId: Int
    let region: String
    let purpose: String
    let university: String?
    let district: String?
    let conditions: [String]
    let monthlyRentMin: Int
    let monthlyRentMax: Int
    let arcStatus: String
    let status: String
    let submittedAt: String
}

struct DiagnosisRecommendationsResponseDTO: Decodable {
    let content: [DiagnosisRecommendedListingResponseDTO]?
    let page: DiagnosisRecommendationPageResponseDTO?
    let suggestions: DiagnosisSuggestionsResponseDTO?
}

struct DiagnosisRecommendedListingResponseDTO: Decodable {
    let listingId: String
    let title: String?
    let type: ListingCodeLabelResponseDTO?
    let monthlyRentMin: Int?
    let monthlyRentMax: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let thumbnailUrl: String?
    let lat: Double?
    let lng: Double?
}

struct DiagnosisRecommendationPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}

struct DiagnosisSuggestionsResponseDTO: Decodable {
    let reason: String?
    let message: String?
    let actions: [DiagnosisSuggestionActionResponseDTO]?
}

struct DiagnosisSuggestionActionResponseDTO: Decodable {
    let type: String?
    let detail: String?
}
