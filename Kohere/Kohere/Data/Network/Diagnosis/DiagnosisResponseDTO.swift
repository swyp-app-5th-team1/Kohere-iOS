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
    // 서버는 `suggestions`(조건 변경 제안)도 내려주지만,
    // 현재 서비스에서 노출하지 않아 별도로 선언하지 않았다. 필요해지면 여기부터 추가한다.
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
