import ComposableArchitecture

struct HideChatRoomUseCase {
    var execute: (_ roomID: Int) async throws -> Void
}

extension HideChatRoomUseCase: DependencyKey {
    static let liveValue: HideChatRoomUseCase = {
        @Dependency(\.chatClient)
        var chatClient
        return HideChatRoomUseCase { try await chatClient.hideRoom($0) }
    }()
}

struct BlockChatRoomUseCase {
    var execute: (_ roomID: Int) async throws -> Void
}

extension BlockChatRoomUseCase: DependencyKey {
    static let liveValue: BlockChatRoomUseCase = {
        @Dependency(\.chatClient)
        var chatClient
        return BlockChatRoomUseCase { try await chatClient.blockRoom($0) }
    }()
}

struct ReportChatRoomUseCase {
    var execute: (_ roomID: Int, _ reason: ChatReportReason) async throws -> ChatReport
}

extension ReportChatRoomUseCase: DependencyKey {
    static let liveValue: ReportChatRoomUseCase = {
        @Dependency(\.chatClient)
        var chatClient
        return ReportChatRoomUseCase { try await chatClient.reportRoom($0, $1) }
    }()
}

extension DependencyValues {
    var hideChatRoomUseCase: HideChatRoomUseCase {
        get { self[HideChatRoomUseCase.self] }
        set { self[HideChatRoomUseCase.self] = newValue }
    }

    var blockChatRoomUseCase: BlockChatRoomUseCase {
        get { self[BlockChatRoomUseCase.self] }
        set { self[BlockChatRoomUseCase.self] = newValue }
    }

    var reportChatRoomUseCase: ReportChatRoomUseCase {
        get { self[ReportChatRoomUseCase.self] }
        set { self[ReportChatRoomUseCase.self] = newValue }
    }
}
