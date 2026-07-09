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
    case updateProfile(UpdateProfileRequestDTO, APIEnvironment)
    case deleteMe(APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .me:
            .get

        case .updateProfile:
            .patch

        case .deleteMe:
            .delete
        }
    }

    private var path: String {
        switch self {
        case .me, .updateProfile, .deleteMe:
            "api/v1/users/me"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .me(environment),
             let .updateProfile(_, environment),
             let .deleteMe(environment):
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
        case let .updateProfile(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .me, .deleteMe:
            break
        }

        return request
    }
}
