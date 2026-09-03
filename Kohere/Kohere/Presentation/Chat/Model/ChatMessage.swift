//
//  ChatMessage.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import Foundation

enum ChatMessageDeliveryStatus: Equatable {
    case queued
    case sending
    case sent
    case failed
}

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
    let clientMessageID: UUID?
    let serverMessageID: Int?
    let deliveryStatus: ChatMessageDeliveryStatus

    init(
        id: String = UUID().uuidString,
        type: ChatMessageType = .text,
        sender: ChatRoomRole,
        originalText: String,
        translatedText: String? = nil,
        timeText: String,
        sentAt: Date? = nil,
        inquiryCard: ChatInquiryCard? = nil,
        bookingCard: ChatRoomModel? = nil,
        clientMessageID: UUID? = nil,
        serverMessageID: Int? = nil,
        deliveryStatus: ChatMessageDeliveryStatus = .sent
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
        self.clientMessageID = clientMessageID
        self.serverMessageID = serverMessageID
        self.deliveryStatus = deliveryStatus
    }
}
