//
//  ChatInterface.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import ComposableArchitecture

protocol ChatInterface {
    func fetchChatRooms(page: Int, size: Int) async throws -> ChatRoomPage
    func fetchChatRoom(roomID: Int) async throws -> ChatRoom
}

struct ChatClient: Sendable {
    var fetchChatRooms: @Sendable (_ page: Int, _ size: Int) async throws -> ChatRoomPage
    var fetchChatRoom: @Sendable (_ roomID: Int) async throws -> ChatRoom
}

extension ChatClient {
    init(repository: any ChatInterface) {
        self.init(
            fetchChatRooms: { page, size in
                try await repository.fetchChatRooms(page: page, size: size)
            },
            fetchChatRoom: { roomID in
                try await repository.fetchChatRoom(roomID: roomID)
            }
        )
    }
}

extension DependencyValues {
    var chatClient: ChatClient {
        get { self[ChatClient.self] }
        set { self[ChatClient.self] = newValue }
    }
}
