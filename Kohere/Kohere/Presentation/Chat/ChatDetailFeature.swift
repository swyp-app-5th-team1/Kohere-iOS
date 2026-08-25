//
//  ChatDetailFeature.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatDetailFeature {
    @Dependency(\.fetchChatRoomUseCase)
    var fetchChatRoomUseCase

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoomModel
        var participantRole: ChatRoomRole
        var hasSubmittedApplication: Bool
        var messages: [ChatMessage]
        var messageText = ""
        var isMoreMenuPresented = false
        var isLoading = false
        var errorMessage: String?

        var showsApplicationBanner: Bool {
            participantRole == .tenant && !hasSubmittedApplication
        }

        var showsKeywordSuggestions: Bool {
            participantRole == .tenant
        }

        init(
            chatRoom: ChatRoomModel,
            participantRole: ChatRoomRole = .tenant,
            hasSubmittedApplication: Bool = true,
            messages: [ChatMessage] = []
        ) {
            self.chatRoom = chatRoom
            self.participantRole = participantRole
            self.hasSubmittedApplication = hasSubmittedApplication
            self.messages = messages
        }
    }

    enum Delegate: Equatable {
        case listingDetailRequested(String)
        case swipeActionRequested(ChatFeature.SwipeAction, roomID: Int)
    }
    
    // MARK: - Action

    enum Action {
        case onAppear
        case chatRoomResponse(Result<ChatRoom, Error>)
        case backButtonTapped
        case viewDetailsButtonTapped
        case applicationBannerTapped
        case messageTextChanged(String)
        case keywordTapped(String)
        case sendButtonTapped
        case moreButtonTapped
        case moreMenuDismissed
        case moreMenuActionTapped(ChatFeature.SwipeAction)
        case delegate(Delegate)
    }
    
    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let roomID = state.chatRoom.roomID
                let fetchChatRoom = fetchChatRoomUseCase
                return .run { send in
                    do {
                        let room = try await fetchChatRoom.execute(roomID)
                        await send(.chatRoomResponse(.success(room)))
                    } catch {
                        await send(.chatRoomResponse(.failure(error)))
                    }
                }

            case let .chatRoomResponse(.success(room)):
                state.isLoading = false
                state.errorMessage = nil
                state.chatRoom = ChatRoomModel(room: room)
                state.participantRole = room.myRole
                return .none

            case let .chatRoomResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .backButtonTapped:
                return .none

            case .viewDetailsButtonTapped:
                return .send(.delegate(.listingDetailRequested(state.chatRoom.listingID)))

            case .applicationBannerTapped:
                // TODO: api 연동
                return .send(.delegate(.listingDetailRequested(state.chatRoom.listingID)))

            case let .messageTextChanged(text):
                state.messageText = text
                return .none

            case let .keywordTapped(keyword):
                let message = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                state.messages.append(Self.localMessage(message, sender: state.participantRole))
                // TODO: api 연동
                return .none

            case .sendButtonTapped:
                let message = state.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                state.messages.append(Self.localMessage(message, sender: state.participantRole))
                state.messageText = ""
                // TODO: api 연동
                return .none

            case .moreButtonTapped:
                state.isMoreMenuPresented.toggle()
                return .none

            case .moreMenuDismissed:
                state.isMoreMenuPresented = false
                return .none

            case let .moreMenuActionTapped(swipeAction):
                state.isMoreMenuPresented = false
                return .send(.delegate(.swipeActionRequested(swipeAction, roomID: state.chatRoom.roomID)))

            case .delegate:
                return .none
            }
        }
    }

    private static func currentTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func localMessage(_ text: String, sender: ChatRoomRole) -> ChatMessage {
        ChatMessage(sender: sender, originalText: text, timeText: currentTimeText())
    }
}
