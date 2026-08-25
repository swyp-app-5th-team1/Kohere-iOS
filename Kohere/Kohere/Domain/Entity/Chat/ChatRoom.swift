//
//  ChatRoom.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Foundation

nonisolated enum ChatRoomRole: String, Equatable, Sendable {
    case tenant = "TENANT"
    case landlord = "LANDLORD"

    init?(userType: UserType) {
        switch userType {
        case .tenant:
            self = .tenant
        case .landlord:
            self = .landlord
        case .unknown:
            return nil
        }
    }
}

nonisolated struct ChatRoom: Equatable, Identifiable, Sendable {
    let roomID: Int
    let myRole: ChatRoomRole
    let listing: ChatRoomListing
    let counterpart: ChatRoomCounterpart
    let isBlocked: Bool
    let lastMessage: ChatRoomLastMessage?

    var id: Int { roomID }
}

nonisolated struct ChatRoomPage: Equatable, Sendable {
    let content: [ChatRoom]
    let page: PageInfo
}

nonisolated struct ChatRoomLastMessage: Equatable, Sendable {
    let messageID: Int?
    let type: ChatMessageType?
    let preview: String?
    let sentAt: Date?
}

nonisolated enum ChatMessageType: String, Equatable, Sendable {
    case text = "TEXT"
    case bookingCard = "BOOKING_CARD"
}

nonisolated struct ChatRoomListing: Equatable, Sendable {
    let listingID: String
    let title: String
    let address: String
}

nonisolated struct ChatRoomCounterpart: Equatable, Sendable {
    let userID: Int
    let displayName: String
}
