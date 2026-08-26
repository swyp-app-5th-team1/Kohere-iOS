//
//  ChatMessage.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import Foundation

struct ChatMessage: Equatable, Identifiable {
    let id: String
    let sender: ChatRoomRole
    let originalText: String
    let translatedText: String?
    let timeText: String
    let sentAt: Date?
    let bookingCard: ChatRoomModel?

    init(
        id: String = UUID().uuidString,
        sender: ChatRoomRole,
        originalText: String,
        translatedText: String? = nil,
        timeText: String,
        sentAt: Date? = nil,
        bookingCard: ChatRoomModel? = nil
    ) {
        self.id = id
        self.sender = sender
        self.originalText = originalText
        self.translatedText = translatedText
        self.timeText = timeText
        self.sentAt = sentAt
        self.bookingCard = bookingCard
    }
}
