//
//  ChatResponseDTO.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

struct ChatRoomPageResponseDTO: Decodable {
    let page: PageResponseDTO
    let content: [ChatRoomResponseDTO]
}

struct ChatRoomResponseDTO: Decodable {
    let chatRoomId: Int
    let myRole: String
    let blocked: Bool
    let counterpart: ChatRoomCounterpartResponseDTO
    let listing: ChatRoomListingResponseDTO
    let lastMessage: ChatRoomLastMessageResponseDTO?
}

struct ChatRoomCounterpartResponseDTO: Decodable {
    let userId: Int
    let displayName: String
}

struct ChatRoomListingResponseDTO: Decodable {
    let listingId: String
    let title: String
    let address: String
}

struct ChatRoomLastMessageResponseDTO: Decodable {
    let messageId: Int?
    let type: String?
    let preview: String?
    let sentAt: String?
}
