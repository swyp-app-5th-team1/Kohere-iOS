//
//  ChatMessage.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

struct ChatMessage: Equatable, Identifiable {
    let id: UUID
    let sender: ChatParticipantRole
    let originalText: String
    let translatedText: String?
    let timeText: String

    init(
        id: UUID = UUID(),
        sender: ChatParticipantRole,
        originalText: String,
        translatedText: String? = nil,
        timeText: String
    ) {
        self.id = id
        self.sender = sender
        self.originalText = originalText
        self.translatedText = translatedText
        self.timeText = timeText
    }
}
