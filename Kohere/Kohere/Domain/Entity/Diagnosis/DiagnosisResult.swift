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

nonisolated struct DiagnosisRecommendationsInput: Equatable {
    static let defaultPageSize = 20

    let diagnosisID: Int
    let page: Int
    let size: Int
    // 현재 화면에서는 정렬을 선택하지 않으므로 nil로 두고 서버 기본 정렬을 사용한다.
    let sort: DiagnosisRecommendationSort?

    init(
        diagnosisID: Int,
        page: Int = 0,
        size: Int = Self.defaultPageSize,
        sort: DiagnosisRecommendationSort? = nil
    ) {
        self.diagnosisID = diagnosisID
        self.page = page
        self.size = size
        self.sort = sort
    }
}

nonisolated struct DiagnosisRecommendationSort: Equatable {
    let field: Field
    let direction: Direction

    var queryValue: String {
        "\(field.rawValue),\(direction.rawValue)"
    }

    enum Field: String, Equatable {
        case recommended
        case price
        case distance
    }

    enum Direction: String, Equatable {
        case ascending = "asc"
        case descending = "desc"
    }
}

struct DiagnosisRecommendations: Equatable {
    let listings: [DiagnosisRecommendedListing]
    let page: PageInfo?
    let suggestions: DiagnosisRecommendationSuggestions?
}

struct DiagnosisRecommendedListing: Equatable, Identifiable {
    nonisolated var id: String { listingID }

    let listingID: String
    let title: String
    let type: String
    let minMonthlyRent: Int?
    let maxMonthlyRent: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let thumbnailURL: String?
    let coordinate: MapCoordinate?
}

struct DiagnosisRecommendationSuggestions: Equatable {
    let reason: String?
    let message: String?
    let actions: [DiagnosisRecommendationSuggestionAction]
}

struct DiagnosisRecommendationSuggestionAction: Equatable {
    let type: String?
    let detail: String?
}
