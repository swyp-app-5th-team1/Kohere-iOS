//
//  APIEnvironment.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import Foundation

struct APIEnvironment {
    let baseURL: URL

    static func live(bundle: Bundle = .main) throws -> APIEnvironment {
        guard
            let rawValue = bundle.object(forInfoDictionaryKey: "KOHERE_API_BASE_URL") as? String,
            !rawValue.isEmpty,
            rawValue != "$(KOHERE_API_BASE_URL)"
        else {
            throw DataError.missingBaseURL
        }

        guard let baseURL = URL(string: rawValue) else {
            throw DataError.invalidURL
        }

        return APIEnvironment(baseURL: baseURL)
    }
}
