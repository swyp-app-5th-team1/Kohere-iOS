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
    case favoriteList(query: ListingFavoriteListQueryDTO, APIEnvironment)
    case recentList(APIEnvironment)
    case addFavorite(listingID: String, APIEnvironment)
    case removeFavorite(listingID: String, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .list, .favoriteList, .recentList:
            .get
        case .addFavorite:
            .post
        case .removeFavorite:
            .delete
        }
    }

    private var path: String {
        switch self {
        case .list:
            "api/v1/listings"
        case .favoriteList:
            "api/v1/users/me/favorites"
        case .recentList:
            "api/v1/users/me/recent-listings"
        case let .addFavorite(listingID, _), let .removeFavorite(listingID, _):
            "api/v1/listings/\(listingID)/favorite"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .list(_, environment):
            environment
        case let .favoriteList(_, environment):
            environment
        case let .recentList(environment):
            environment
        case let .addFavorite(_, environment):
            environment
        case let .removeFavorite(_, environment):
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
        case let .list(query, _):
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw DataError.invalidURL
            }
            components.queryItems = query.queryItems
            guard let requestURL = components.url else {
                throw DataError.invalidURL
            }
            request.url = requestURL

        case let .favoriteList(query, _):
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw DataError.invalidURL
            }
            components.queryItems = query.queryItems
            guard let requestURL = components.url else {
                throw DataError.invalidURL
            }
            request.url = requestURL

        case .recentList, .addFavorite, .removeFavorite:
            break
        }

        return request
    }
}
