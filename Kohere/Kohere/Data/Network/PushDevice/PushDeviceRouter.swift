//
//  PushDeviceRouter.swift
//  Kohere
//
//  Created by 송규섭 on 9/1/26.
//

import Alamofire
import Foundation

enum PushDeviceRouter: URLRequestConvertible {
    case register(installationId: String, RegisterPushDeviceRequestDTO, APIEnvironment)
    case unregister(installationId: String, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .register:
            .put

        case .unregister:
            .delete
        }
    }

    private var path: String {
        switch self {
        case let .register(installationId, _, _),
             let .unregister(installationId, _):
            "api/v1/users/me/push-devices/\(installationId)"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .register(_, _, environment),
             let .unregister(_, environment):
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
        case let .register(_, requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .unregister:
            break
        }

        return request
    }
}
