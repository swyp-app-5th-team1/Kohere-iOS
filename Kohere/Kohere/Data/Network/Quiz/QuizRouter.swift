//
//  QuizRouter.swift
//  Kohere
//
//  Created by mandoo on 7/7/26.
//

import Alamofire
import Foundation

enum QuizRouter: URLRequestConvertible {
    case random(APIEnvironment)
    case answer(quizID: Int, requestDTO: QuizAnswerRequestDTO, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .random:
            .get
        case .answer:
            .post
        }
    }

    private var path: String {
        switch self {
        case .random:
            "api/v1/quizzes/random"
        case let .answer(quizID, _, _):
            "api/v1/quizzes/\(quizID)/answer"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .random(environment):
            environment
        case let .answer(_, _, environment):
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
        case .random:
            break
        case let .answer(_, requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)
        }

        return request
    }
}
