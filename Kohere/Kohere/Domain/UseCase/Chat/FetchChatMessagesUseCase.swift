import ComposableArchitecture

struct FetchChatMessagesUseCase {
    var execute: (_ roomID: Int, _ cursor: String?, _ afterMessageID: Int?, _ size: Int) async throws -> ChatMessagePage
}

extension FetchChatMessagesUseCase: DependencyKey {
    static let liveValue: FetchChatMessagesUseCase = {
        @Dependency(\.chatClient)
        var chatClient
        return FetchChatMessagesUseCase { roomID, cursor, afterMessageID, size in
            try await chatClient.fetchMessages(roomID, cursor, afterMessageID, size)
        }
    }()
}

extension DependencyValues {
    var fetchChatMessagesUseCase: FetchChatMessagesUseCase {
        get { self[FetchChatMessagesUseCase.self] }
        set { self[FetchChatMessagesUseCase.self] = newValue }
    }
}
