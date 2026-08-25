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
