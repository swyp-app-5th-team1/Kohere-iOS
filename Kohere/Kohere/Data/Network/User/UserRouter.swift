//
//  UserRouter.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

enum UserRouter: URLRequestConvertible {
    case me(APIEnvironment)
    case deleteMe(APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .me:
            .get

        case .deleteMe:
            .delete
        }
    }

    private var path: String {
        switch self {
        case .me, .deleteMe:
            "api/v1/users/me"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .me(environment),
             let .deleteMe(environment):
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
