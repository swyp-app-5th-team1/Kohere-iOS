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
    let bookingCard: ChatApplicationCard?
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
        bookingCard: ChatApplicationCard? = nil,
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

    init(storedMessage: StoredChatMessage, room: ChatRoomModel) {
        let sender: ChatRoomRole = storedMessage.isMine ? room.myRole : room.myRole.counterpart
        self.init(
            id: "server-\(storedMessage.messageID)",
            type: storedMessage.type,
            sender: sender,
            originalText: storedMessage.originalContent ?? "",
            translatedText: storedMessage.translatedContent,
            timeText: ChatTimestampFormatter.timeText(storedMessage.sentAt),
            sentAt: storedMessage.sentAt,
            inquiryCard: storedMessage.inquiryCard,
            bookingCard: storedMessage.bookingCard.map {
                ChatApplicationCard(booking: $0, room: room, sentAt: storedMessage.sentAt)
            },
            serverMessageID: storedMessage.messageID
        )
    }

    func updating(
        serverMessageID: Int? = nil,
        sentAt: Date? = nil,
        deliveryStatus: ChatMessageDeliveryStatus
    ) -> ChatMessage {
        let resolvedDate = sentAt ?? self.sentAt
        return ChatMessage(
            id: id,
            type: type,
            sender: sender,
            originalText: originalText,
            translatedText: translatedText,
            timeText: resolvedDate.map(ChatTimestampFormatter.timeText) ?? timeText,
            sentAt: resolvedDate,
            inquiryCard: inquiryCard,
            bookingCard: bookingCard,
            clientMessageID: clientMessageID,
            serverMessageID: serverMessageID ?? self.serverMessageID,
            deliveryStatus: deliveryStatus
        )
    }
}

extension ChatRoomRole {
    var counterpart: ChatRoomRole {
        self == .tenant ? .landlord : .tenant
    }
}

nonisolated enum ChatTimestampFormatter {
    static func timeText(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
