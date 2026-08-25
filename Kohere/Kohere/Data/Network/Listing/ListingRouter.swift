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
    case map(query: ListingMapQueryDTO, APIEnvironment)
    case detail(listingID: String, APIEnvironment)
    case favoriteList(query: ListingFavoriteListQueryDTO, APIEnvironment)
    case recentList(APIEnvironment)
    case addFavorite(listingID: String, APIEnvironment)
    case removeFavorite(listingID: String, APIEnvironment)
    case createBooking(listingID: String, request: ListingBookingCreateRequestDTO, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .list, .map, .detail, .favoriteList, .recentList:
            .get
        case .addFavorite, .createBooking:
            .post
        case .removeFavorite:
            .delete
        }
    }

    private var path: String {
        switch self {
        case .list:
            "api/v2/listings"
        case .map:
            "api/v2/listings/map"
        case let .detail(listingID, _):
            "api/v2/listings/\(listingID)"
        case .favoriteList:
            "api/v2/users/me/favorites"
        case .recentList:
            "api/v2/users/me/recent-listings"
        case let .addFavorite(listingID, _), let .removeFavorite(listingID, _):
            "api/v1/listings/\(listingID)/favorite"
        case let .createBooking(listingID, _, _):
            "api/v1/listings/\(listingID)/bookings"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .list(_, environment):
            environment
        case let .map(_, environment):
            environment
        case let .detail(_, environment):
            environment
        case let .favoriteList(_, environment):
            environment
        case let .recentList(environment):
            environment
        case let .addFavorite(_, environment):
            environment
        case let .removeFavorite(_, environment):
            environment
        case let .createBooking(_, _, environment):
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

        case let .map(query, _):
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

        case .detail, .recentList, .addFavorite, .removeFavorite:
            break

        case let .createBooking(_, requestDTO, _):
            request.httpBody = try JSONEncoder().encode(requestDTO)
        }

        return request
    }
}
