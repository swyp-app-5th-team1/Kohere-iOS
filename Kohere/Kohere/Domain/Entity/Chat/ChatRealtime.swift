//
//  ChatRealtime.swift
//  Kohere
//
//  Created by soomin on 8/28/26.
//

import Foundation

nonisolated struct ChatStompGuide: Equatable, Sendable {
    let developmentWebSocketURL: URL
    let localWebSocketURL: URL
    let webSocketEndpoint: String
    let connectHeaderName: String
    let connectHeaderValueFormat: String
    let controlQueue: String
    let ackQueue: String
    let errorQueue: String
    let roomEventQueue: String
    let translationQueue: String
    let controlSendDestination: String
    let roomSubscribeDestination: String
    let messageSendDestination: String
    let maxTextCodePoints: Int
    let heartbeatSeconds: Int
}

nonisolated enum ChatRealtimeConnectionState: Equatable, Sendable {
    case connecting
    case ready
    case disconnected
}

nonisolated struct ChatTextAcknowledgement: Equatable, Sendable {
    let clientMessageID: UUID
    let messageID: Int
    let sentAt: Date
    let duplicate: Bool
}

nonisolated struct ChatTextFailure: Equatable, Sendable {
    let clientMessageID: UUID?
    let code: String
    let message: String
}

nonisolated struct ChatTranslatedMessage: Equatable, Sendable {
    let messageID: Int
    let clientMessageID: UUID?
    let roomID: Int
    let senderID: Int
    let originalContent: String
    let translatedContent: String?
    let sentAt: Date
}

nonisolated struct ChatRoomSubscription: Equatable, Sendable {
    let roomID: Int
    let highWatermark: Int?
}

nonisolated enum ChatRealtimeEvent: Equatable, Sendable {
    case connection(ChatRealtimeConnectionState)
    case subscriptionReady(ChatRoomSubscription)
    case acknowledgement(ChatTextAcknowledgement)
    case sendFailure(ChatTextFailure)
    case translatedMessage(ChatTranslatedMessage)
    case roomMessage(StoredChatMessage)
    case roomListChanged
}
