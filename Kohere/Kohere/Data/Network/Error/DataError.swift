//
//  DataError.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import Foundation

enum DataError: Error, Equatable {
    case missingBaseURL
    case missingNaverSearchCredentials
    case invalidURL
    case emptyResponse
    case decodingFailed
    case httpStatus(code: Int, message: String?)
    case serverError(code: String, message: String)
    case underlying(message: String)
}

extension DataError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            "API Base URL이 설정되지 않았습니다."

        case .missingNaverSearchCredentials:
            "네이버 검색 API 키가 설정되지 않았습니다."

        case .invalidURL:
            "요청 URL을 만들 수 없습니다."

        case .emptyResponse:
            "서버 응답 데이터가 비어 있습니다."

        case .decodingFailed:
            "서버 응답을 해석할 수 없습니다."

        case let .httpStatus(code, message):
            message ?? "HTTP 요청이 실패했습니다. statusCode=\(code)"

        case let .serverError(_, message):
            message

        case let .underlying(message):
            message
        }
    }
}
