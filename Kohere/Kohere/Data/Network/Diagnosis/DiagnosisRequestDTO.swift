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

extension DiagnosisRecommendationsQueryDTO {
    init(_ input: DiagnosisRecommendationsInput) {
        self.init(
            page: input.page,
            size: input.size,
            sort: input.sort?.queryValue
        )
    }
}

nonisolated enum DiagnosisAnswerRequestDTO: Encodable, Sendable {
    case single(field: String, code: String)
    case multiple(field: String, codes: [String])
    case monthlyRent(field: String, min: Int, max: Int)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .single(field, code):
            try container.encode(field, forKey: .field)
            try container.encode(code, forKey: .code)

        case let .multiple(field, codes):
            try container.encode(field, forKey: .field)
            try container.encode(codes, forKey: .codes)

        case let .monthlyRent(field, min, max):
            try container.encode(field, forKey: .field)
            try container.encode(min, forKey: .min)
            try container.encode(max, forKey: .max)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case field
        case code
        case codes
        case min
        case max
    }
}
