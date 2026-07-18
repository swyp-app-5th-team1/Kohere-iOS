//
//  PlaceSearchRouter.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

enum PlaceSearchRouter: URLRequestConvertible {
    case search(query: PlaceSearchQueryDTO, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .search:
            .get
        }
    }

    private var path: String {
        switch self {
        case .search:
            "api/v1/listings/places"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .search(_, environment):
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
        case let .search(query, _):
            request = try URLEncodedFormParameterEncoder.default.encode(query, into: request)
        }

        return request
    }
}
