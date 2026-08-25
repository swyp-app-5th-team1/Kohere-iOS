//
//  FetchChatRoomUseCase.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import ComposableArchitecture

struct FetchChatRoomUseCase {
    var execute: (_ roomID: Int) async throws -> ChatRoom
}

extension FetchChatRoomUseCase: DependencyKey {
    static let liveValue: FetchChatRoomUseCase = {
        @Dependency(\.chatClient)
        var chatClient

        return FetchChatRoomUseCase { roomID in
            try await chatClient.fetchChatRoom(roomID)
        }
    }()
}

extension DependencyValues {
    var fetchChatRoomUseCase: FetchChatRoomUseCase {
        get { self[FetchChatRoomUseCase.self] }
        set { self[FetchChatRoomUseCase.self] = newValue }
    }
}
