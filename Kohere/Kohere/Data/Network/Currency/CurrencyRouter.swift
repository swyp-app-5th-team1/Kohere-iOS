//
//  CurrencyRouter.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Alamofire
import Foundation

enum CurrencyRouter: URLRequestConvertible {
    case krwToUSDExchangeRate

    private var method: HTTPMethod {
        switch self {
        case .krwToUSDExchangeRate:
            .get
        }
    }

    private var urlString: String {
        switch self {
        case .krwToUSDExchangeRate:
            "https://api.frankfurter.dev/v2/rate/KRW/USD"
        }
    }

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw DataError.invalidURL
        }

        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
