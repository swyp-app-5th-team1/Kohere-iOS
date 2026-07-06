//
//  DiagnosisRouter.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

enum DiagnosisRouter: URLRequestConvertible {
    case question(step: Int, environment: APIEnvironment)
    case saveAnswer(DiagnosisAnswerRequestDTO, environment: APIEnvironment)
    case submit(environment: APIEnvironment)
    case detail(diagnosisID: Int, APIEnvironment)
    case recommendations(
        diagnosisID: Int,
        query: DiagnosisRecommendationsQueryDTO,
        APIEnvironment
    )

    private var method: HTTPMethod {
        switch self {
        case .question, .detail, .recommendation:
            .get

        case .saveAnswer, .submit:
            .post
        }
    }

    private var path: String {
        switch self {
        case let .question(step, _):
            "api/v1/diagnoses/questions/\(step)"

        case .saveAnswer:
            "api/v1/diagnoses/answers"

        case .submit:
            "api/v1/diagnoses"

        case let .detail(diagnosisID, _):
            "api/v1/diagnoses/\(diagnosisID)"

        case let .recommendations(diagnosisID, _, _):
            "api/v1/diagnoses/\(diagnosisID)/recommendations"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .question(_, environment),
             let .saveAnswer(_, environment),
			 let .submit(environment),
			 let .detail(_, environment),
             let .recommendations(_, _, environment):
            environment
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
		case let .recommendations(_, query, _):
			request = try URLEncodedFormParameterEncoder.default.encode(query, into: request)

        case let .saveAnswer(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .detail, .question, .submit:
            break
        }

        return request
    }
}
