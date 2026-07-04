//
//  DiagnosisResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

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
    let markers: [DiagnosisRecommendationMarkerResponseDTO]?
}

struct DiagnosisRecommendedListingResponseDTO: Decodable {
    let listingId: String
    let title: String?
    let type: String?
    let monthlyRent: Int?
    let deposit: Int?
    let thumbnailUrl: String?
    let lat: Double?
    let lng: Double?
    let conditions: [String]?
}

struct DiagnosisRecommendationMarkerResponseDTO: Decodable {
    let listingId: String
    let lat: Double?
    let lng: Double?
}
