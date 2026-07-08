//
//  BookingRequestDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

struct BookingListQueryDTO {
    let page: Int
    let size: Int
    
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
    }
}
