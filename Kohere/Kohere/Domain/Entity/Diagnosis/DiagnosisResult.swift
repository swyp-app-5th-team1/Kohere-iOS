//
//  DiagnosisResult.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

struct DiagnosisDetail: Equatable {
    let diagnosisID: Int
    let region: String
    let purpose: String
    let university: String?
    let district: String?
    let conditions: [RoomCondition]
    let monthlyRentMin: Int
    let monthlyRentMax: Int
    let arcStatus: String
    let status: String
    let submittedAt: String
}

struct DiagnosisRecommendations: Equatable {
    let listings: [DiagnosisRecommendedListing]
    let markers: [MapMarkerItem]
}

struct DiagnosisRecommendedListing: Equatable {
    let listingID: String
    let title: String
    let type: String
    let monthlyRent: Int?
    let deposit: Int?
    let thumbnailURL: String?
    let coordinate: MapCoordinate?
    let conditions: [RoomCondition]
}
