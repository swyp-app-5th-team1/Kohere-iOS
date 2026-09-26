//
//  ChatRoomModel.swift
//  Kohere
//
//  Created by soomin on 6/29/26.
//

import Foundation

nonisolated struct ChatRoomModel: Equatable, Identifiable {
    let roomID: Int
    let myRole: ChatRoomRole
    let listingID: String
    let listingName: String
    let location: String
    let counterpartName: String
    var isBlocked: Bool
    let lastMessageType: ChatMessageType?
    let lastMessagePreview: String?
    let thumbnailURL: String?
    let createdAt: Date?

    var id: Int { roomID }
    var timeText: String { ChatTimestampFormatter.timeText(createdAt) }

    init(
        roomID: Int,
        myRole: ChatRoomRole = .tenant,
        listingID: String,
        listingName: String,
        location: String,
        counterpartName: String = "",
        isBlocked: Bool = false,
        lastMessageType: ChatMessageType? = nil,
        lastMessagePreview: String? = nil,
        thumbnailURL: String? = nil,
        createdAt: Date? = nil
    ) {
        self.roomID = roomID
        self.myRole = myRole
        self.listingID = listingID
        self.listingName = listingName
        self.location = location
        self.counterpartName = counterpartName
        self.isBlocked = isBlocked
        self.lastMessageType = lastMessageType
        self.lastMessagePreview = lastMessagePreview
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }

    init(room: ChatRoom) {
        self.init(
            roomID: room.roomID,
            myRole: room.myRole,
            listingID: room.listing.listingID,
            listingName: room.listing.title,
            location: room.listing.address,
            counterpartName: room.counterpart.displayName,
            isBlocked: room.isBlocked,
            lastMessageType: room.lastMessage?.type,
            lastMessagePreview: room.lastMessage?.preview,
            createdAt: room.lastMessage?.sentAt
        )
    }
}
