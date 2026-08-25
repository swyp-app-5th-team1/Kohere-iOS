//
//  ChatRoom.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Foundation

enum ChatRoomRole: String, Equatable, Sendable {
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

    var id: Int { roomID }
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
