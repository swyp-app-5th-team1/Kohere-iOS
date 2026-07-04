//
//  DiagnosisRouter.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

enum DiagnosisRouter: URLRequestConvertible {
    case detail(diagnosisID: Int, APIEnvironment)
    case recommendations(
        diagnosisID: Int,
        query: DiagnosisRecommendationsQueryDTO,
        APIEnvironment
    )

    private var method: HTTPMethod {
        switch self {
        case .detail, .recommendations:
            .get
        }
    }

    private var path: String {
        switch self {
        case let .detail(diagnosisID, _):
            "api/v1/diagnoses/\(diagnosisID)"

        case let .recommendations(diagnosisID, _, _):
            "api/v1/diagnoses/\(diagnosisID)/recommendations"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .detail(_, environment),
             let .recommendations(_, _, environment):
            environment
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case .detail:
            return request

        case let .recommendations(_, query, _):
            return try URLEncodedFormParameterEncoder.default.encode(query, into: request)
        }
    }
}
