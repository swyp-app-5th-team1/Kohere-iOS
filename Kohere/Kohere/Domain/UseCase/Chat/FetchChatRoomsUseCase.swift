//
//  FetchChatRoomsUseCase.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import ComposableArchitecture

struct FetchChatRoomsUseCase {
    var execute: (_ page: Int, _ size: Int) async throws -> ChatRoomPage
}

extension FetchChatRoomsUseCase: DependencyKey {
    static let liveValue: FetchChatRoomsUseCase = {
        @Dependency(\.chatClient)
        var chatClient

        return FetchChatRoomsUseCase { page, size in
            try await chatClient.fetchChatRooms(page, size)
        }
    }()
}

extension DependencyValues {
    var fetchChatRoomsUseCase: FetchChatRoomsUseCase {
        get { self[FetchChatRoomsUseCase.self] }
        set { self[FetchChatRoomsUseCase.self] = newValue }
    }
}
