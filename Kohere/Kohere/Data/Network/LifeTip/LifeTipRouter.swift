//
//  LifeTipRouter.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

import Alamofire
import Foundation

// MARK: - Router

enum LifeTipRouter: URLRequestConvertible {
    case topics(APIEnvironment)
    case tips(topicCode: String, APIEnvironment)

    private var method: HTTPMethod { .get }

    private var path: String {
        switch self {
        case .topics:
            "api/v1/life-tips/topics"

        case let .tips(topicCode, _):
            "api/v1/life-tips/topics/\(topicCode)/tips"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .topics(environment):
            environment

        case let .tips(_, environment):
            environment
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
