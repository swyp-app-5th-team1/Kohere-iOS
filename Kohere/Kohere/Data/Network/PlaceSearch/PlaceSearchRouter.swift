//
//  PlaceSearchRouter.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

enum PlaceSearchRouter: URLRequestConvertible {
    case localSearch(query: PlaceSearchQueryDTO, clientID: String, clientSecret: String)

    private var method: HTTPMethod {
        switch self {
        case .localSearch:
            .get
        }
    }

    private var urlString: String {
        switch self {
        case .localSearch:
            "https://openapi.naver.com/v1/search/local.json"
        }
    }

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw DataError.invalidURL
        }

        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case let .localSearch(query, clientID, clientSecret):
            request.setValue(clientID, forHTTPHeaderField: "X-Naver-Client-Id")
            request.setValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
            request = try URLEncodedFormParameterEncoder.default.encode(query, into: request)
        }

        return request
    }
}
