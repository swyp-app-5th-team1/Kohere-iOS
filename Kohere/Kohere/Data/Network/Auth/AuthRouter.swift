//
//  AuthRouter.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import Alamofire
import Foundation

enum AuthRouter: URLRequestConvertible {
    case socialLogin(SocialLoginRequestDTO, APIEnvironment)
    case reissue(ReissueTokenRequestDTO, APIEnvironment)
    case logout(LogoutRequestDTO, accessToken: String, environment: APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .socialLogin, .reissue, .logout:
            .post
        }
    }

    private var path: String {
        switch self {
        case .socialLogin:
            "api/v1/auth/social-login"

        case .reissue:
            "api/v1/auth/reissue"

        case .logout:
            "api/v1/auth/logout"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .socialLogin(_, environment),
             let .reissue(_, environment),
             let .logout(_, _, environment):
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
        case let .socialLogin(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .reissue(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .logout(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)
        }

        return request
    }
}
