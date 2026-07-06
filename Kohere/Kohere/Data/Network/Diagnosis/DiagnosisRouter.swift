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

    private var method: HTTPMethod {
        switch self {
        case .question:
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
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .question(_, environment),
             let .saveAnswer(_, environment),
             let .submit(environment):
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
        case let .saveAnswer(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .question, .submit:
            break
        }

        return request
    }
}
