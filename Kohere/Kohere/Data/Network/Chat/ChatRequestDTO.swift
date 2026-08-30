//
//  ChatRequestDTO.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Foundation

struct ChatRoomListQueryDTO {
    let page: Int
    let size: Int

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
    }
}

struct ChatMessageHistoryQueryDTO {
    let cursor: String?
    let afterMessageID: Int?
    let size: Int

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "size", value: "\(size)")]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        if let afterMessageID { items.append(URLQueryItem(name: "afterMessageId", value: "\(afterMessageID)")) }
        return items
    }
}
