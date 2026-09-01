//
//  ChatRouter.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Alamofire
import Foundation

enum ChatRouter: URLRequestConvertible {
    case stompGuide(APIEnvironment)
    case roomList(query: ChatRoomListQueryDTO, APIEnvironment)
    case roomDetail(roomID: Int, APIEnvironment)
    case messageHistory(roomID: Int, query: ChatMessageHistoryQueryDTO, APIEnvironment)
    case createInquiry(listingID: String, APIEnvironment)
    case hideRoom(roomID: Int, APIEnvironment)
    case blockRoom(roomID: Int, APIEnvironment)
    case reportRoom(roomID: Int, request: ChatRoomReportRequestDTO, APIEnvironment)

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if case let .reportRoom(_, body, _) = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let queryItems: [URLQueryItem]?
        switch self {
        case let .roomList(query, _): queryItems = query.queryItems
        case let .messageHistory(_, query, _): queryItems = query.queryItems
        default: queryItems = nil
        }
        if let queryItems {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw DataError.invalidURL
            }
            components.queryItems = queryItems
            guard let requestURL = components.url else {
                throw DataError.invalidURL
            }
            request.url = requestURL
        }

        return request
    }

    private var path: String {
        switch self {
        case .stompGuide:
            "api/v1/chat/stomp-guide"
        case .roomList:
            "api/v1/chat-rooms"
        case let .roomDetail(roomID, _):
            "api/v1/chat-rooms/\(roomID)"
        case let .messageHistory(roomID, _, _):
            "api/v1/chat-rooms/\(roomID)/messages"
        case let .createInquiry(listingID, _):
            "api/v1/listings/\(listingID)/inquiries"
        case let .hideRoom(roomID, _):
            "api/v1/chat-rooms/\(roomID)"
        case let .blockRoom(roomID, _):
            "api/v1/chat-rooms/\(roomID)/block"
        case let .reportRoom(roomID, _, _):
            "api/v1/chat-rooms/\(roomID)/reports"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .stompGuide(environment),
             let .roomList(_, environment),
             let .roomDetail(_, environment),
             let .messageHistory(_, _, environment),
             let .createInquiry(_, environment),
             let .hideRoom(_, environment),
             let .blockRoom(_, environment),
             let .reportRoom(_, _, environment):
            environment
        }
    }

    private var method: HTTPMethod {
        switch self {
        case .stompGuide, .roomList, .roomDetail, .messageHistory:
            .get
        case .createInquiry, .blockRoom, .reportRoom:
            .post
        case .hideRoom:
            .delete
        }
    }
}
