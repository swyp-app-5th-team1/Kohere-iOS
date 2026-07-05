//
//  DiagnosisRouter.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

enum DiagnosisRouter: URLRequestConvertible {
    case question(step: Int, accessToken: String, environment: APIEnvironment)
    case saveAnswer(DiagnosisAnswerRequestDTO, accessToken: String, environment: APIEnvironment)
    case submit(accessToken: String, environment: APIEnvironment)

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
        case let .question(step, _, _):
            "api/v1/diagnoses/questions/\(step)"

        case .saveAnswer:
            "api/v1/diagnoses/answers"

        case .submit:
            "api/v1/diagnoses"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .question(_, _, environment),
             let .saveAnswer(_, _, environment),
             let .submit(_, environment):
            environment
        }
    }

    private var accessToken: String {
        switch self {
        case let .question(_, accessToken, _),
             let .saveAnswer(_, accessToken, _),
             let .submit(accessToken, _):
            accessToken
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        switch self {
        case let .saveAnswer(requestDTO, _, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .question, .submit:
            break
        }

        return request
    }
}
