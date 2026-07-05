//
//  ListingRouter.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import Alamofire
import Foundation

enum ListingRouter: URLRequestConvertible {
    case list(query: ListingListQueryDTO, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .list:
            .get
        }
    }

    private var path: String {
        switch self {
        case .list:
            "api/v1/listings"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .list(_, environment):
            environment
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case let .list(query, _):
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw DataError.invalidURL
            }
            components.queryItems = query.queryItems
            guard let requestURL = components.url else {
                throw DataError.invalidURL
            }
            request.url = requestURL
        }

        return request
    }
}
