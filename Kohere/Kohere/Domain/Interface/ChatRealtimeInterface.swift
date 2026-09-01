//
//  ChatRealtimeInterface.swift
//  Kohere
//

import ComposableArchitecture
import Foundation

struct ChatRealtimeClient: Sendable {
    var connect: @MainActor @Sendable (_ roomID: Int) async throws -> AsyncStream<ChatRealtimeEvent>
    var disconnect: @MainActor @Sendable () async -> Void
    var sendText: @MainActor @Sendable (_ roomID: Int, _ clientMessageID: UUID, _ content: String) async throws -> Void
}

extension ChatRealtimeClient: DependencyKey {
    static let liveValue: ChatRealtimeClient = {
        let service = ChatRealtimeService()
        return ChatRealtimeClient(
            connect: { try await service.connect(roomID: $0) },
            disconnect: { await service.disconnect() },
            sendText: { try await service.sendText(roomID: $0, clientMessageID: $1, content: $2) }
        )
    }()

    static let testValue = ChatRealtimeClient(
        connect: { _ in AsyncStream { $0.finish() } },
        disconnect: {},
        sendText: { _, _, _ in }
    )
}

extension DependencyValues {
    var chatRealtimeClient: ChatRealtimeClient {
        get { self[ChatRealtimeClient.self] }
        set { self[ChatRealtimeClient.self] = newValue }
    }
}
