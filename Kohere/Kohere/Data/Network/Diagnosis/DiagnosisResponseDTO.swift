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
    let page: PageResponseDTO?
    let suggestions: DiagnosisSuggestionsResponseDTO?
}

struct DiagnosisRecommendationMapResponseDTO: Decodable {
    let markers: [ListingMapMarkerResponseDTO]
    let total: Int
}

extension DiagnosisRecommendationMapResponseDTO {
    func toEntity() -> DiagnosisRecommendationMap {
        DiagnosisRecommendationMap(
            markers: markers.compactMap { marker in
                guard let id = marker.listingId, let lat = marker.lat, let lng = marker.lng else { return nil }
                return ListingMapMarker(listingID: id, coordinate: .init(latitude: lat, longitude: lng))
            },
            total: total
        )
    }
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
    // 일반 매물 조회와 같은 구조. 서버 반영 전 누락/null 응답도 허용한다.
    let nearestTransit: ListingNearestTransitResponseDTO?
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
