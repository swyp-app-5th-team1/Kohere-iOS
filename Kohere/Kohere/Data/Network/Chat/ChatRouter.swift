//
//  ChatRouter.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Alamofire
import Foundation

enum ChatRouter: URLRequestConvertible {
    case roomList(query: ChatRoomListQueryDTO, APIEnvironment)
    case roomDetail(roomID: Int, APIEnvironment)

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = .get
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if case let .roomList(query, _) = self {
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

    private var path: String {
        switch self {
        case .roomList:
            "api/v1/chat-rooms"
        case let .roomDetail(roomID, _):
            "api/v1/chat-rooms/\(roomID)"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .roomList(_, environment),
             let .roomDetail(_, environment):
            environment
        }
    }
}
