//
//  BookingRouter.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

enum BookingRouter: URLRequestConvertible {
    case list(query: BookingListQueryDTO, APIEnvironment)
    case detail(bookingID: Int, APIEnvironment)
    case delete(bookingID: Int, APIEnvironment)
    case block(bookingID: Int, APIEnvironment)
    case report(bookingID: Int, APIEnvironment)
    
    private var method: HTTPMethod {
        switch self {
        case .list, .detail:
            .get
        case .delete:
            .delete
        case .block, .report:
            .post
        }
    }
    
    private var path: String {
        switch self {
        case .list:
            "api/v1/bookings"
        case let .detail(bookingID, _):
            "api/v1/bookings/\(bookingID)"
        case let .delete(bookingID, _):
            "api/v1/bookings/\(bookingID)"
        case let .block(bookingID, _):
            "api/v1/bookings/\(bookingID)/block"
        case let .report(bookingID, _):
            "api/v1/bookings/\(bookingID)/report"
        }
    }
    
    private var environment: APIEnvironment {
        switch self {
        case let .list(_, environment),
             let .detail(_, environment),
             let .delete(_, environment),
             let .block(_, environment),
             let .report(_, environment):
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
            
        case .detail, .delete, .block, .report:
            break
        }
        
        return request
    }
}
