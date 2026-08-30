//
//  ChatMessage.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import Foundation

struct ChatMessage: Equatable, Identifiable {
    let id: String
    let type: ChatMessageType
    let sender: ChatRoomRole
    let originalText: String
    let translatedText: String?
    let timeText: String
    let sentAt: Date?
    let inquiryCard: ChatInquiryCard?
    let bookingCard: ChatRoomModel?

    init(
        id: String = UUID().uuidString,
        type: ChatMessageType = .text,
        sender: ChatRoomRole,
        originalText: String,
        translatedText: String? = nil,
        timeText: String,
        sentAt: Date? = nil,
        inquiryCard: ChatInquiryCard? = nil,
        bookingCard: ChatRoomModel? = nil
    ) {
        self.id = id
        self.type = type
        self.sender = sender
        self.originalText = originalText
        self.translatedText = translatedText
        self.timeText = timeText
        self.sentAt = sentAt
        self.inquiryCard = inquiryCard
        self.bookingCard = bookingCard
    }
}
