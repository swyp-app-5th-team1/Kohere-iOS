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
    @Dependency(\.fetchChatMessagesUseCase)
    var fetchChatMessagesUseCase
    @Dependency(\.chatRealtimeClient)
    var chatRealtimeClient
    @Dependency(\.uuid)
    var uuid
    @Dependency(\.date.now)
    var now

    nonisolated enum EffectID {
        case room
        case messages
        case missedMessages
        case realtime
    }

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoomModel
        var hasSubmittedApplication: Bool
        var messages: [ChatMessage]
        var messageText = ""
        var isMoreMenuPresented = false
        var isLoading = false
        var isMessagesLoading = false
        var hasLoadedMessages = false
        var nextCursor: String?
        var hasOlderMessages = false
        var shouldRetryBookingCard: Bool
        var showsInquiryCard: Bool
        var errorMessage: String?
        var isRealtimeReady = false
        var selectedFailedMessageID: UUID?

        var participantRole: ChatRoomRole {
            chatRoom.myRole
        }

        var showsApplicationBanner: Bool {
            participantRole == .tenant && showsInquiryCard && hasLoadedMessages && !hasSubmittedApplication
        }

        var showsKeywordSuggestions: Bool {
            participantRole == .tenant
        }

        init(
            chatRoom: ChatRoomModel,
            hasSubmittedApplication: Bool = false,
            messages: [ChatMessage] = [],
            shouldRetryBookingCard: Bool = false,
            showsInquiryCard: Bool = false
        ) {
            self.chatRoom = chatRoom
            self.hasSubmittedApplication = hasSubmittedApplication
            self.messages = messages
            self.shouldRetryBookingCard = shouldRetryBookingCard
            self.showsInquiryCard = showsInquiryCard
        }
    }

    @CasePathable
    enum Delegate: Equatable {
        case dismissRequested
        case listingDetailRequested(String, isApplicationDisabled: Bool)
        case swipeActionRequested(ChatFeature.SwipeAction, roomID: Int)
        case errorMessageRequested(String)
    }
    
    // MARK: - Action

    enum Action {
        case onAppear
        case onDisappear
        case chatRoomResponse(Result<ChatRoom, Error>)
        case messageHistoryResponse(isInitial: Bool, Result<ChatMessagePage, Error>)
        case missedMessagesResponse(Result<ChatMessagePage, Error>)
        case realtimeConnectionResponse(Result<AsyncStream<ChatRealtimeEvent>, Error>)
        case realtimeEvent(ChatRealtimeEvent)
        case textSendResponse(clientMessageID: UUID, Result<Void, Error>)
        case loadPreviousMessages
        case retryBookingCard
        case backButtonTapped
        case viewDetailsButtonTapped(listingID: String)
        case applicationBannerTapped
        case messageTextChanged(String)
        case keywordTapped(String)
        case sendButtonTapped
        case retryFailedMessageTapped(UUID)
        case failedMessageDeleteButtonTapped(UUID)
        case failedMessageDialogDismissed
        case selectedFailedMessageResendTapped
        case selectedFailedMessageDeleteTapped
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
                let roomEffect: Effect<Action> = .run { send in
                    do {
                        let room = try await fetchChatRoom.execute(roomID)
                        await send(.chatRoomResponse(.success(room)))
                    } catch {
                        await send(.chatRoomResponse(.failure(error)))
                    }
                }
                .cancellable(id: EffectID.room, cancelInFlight: true)
                let realtimeEffect = connectRealtime(roomID: roomID)
                guard !state.hasLoadedMessages, !state.isMessagesLoading else {
                    return .merge(roomEffect, realtimeEffect)
                }
                state.isMessagesLoading = true
                return .merge(roomEffect, fetchMessages(roomID: roomID, cursor: nil, isInitial: true), realtimeEffect)

            case .onDisappear:
                state.isRealtimeReady = false
                let disconnect = chatRealtimeClient.disconnect
                return .merge(
                    .cancel(id: EffectID.room),
                    .cancel(id: EffectID.messages),
                    .cancel(id: EffectID.missedMessages),
                    .cancel(id: EffectID.realtime),
                    .run { _ in await disconnect() }
                )

            case let .chatRoomResponse(.success(room)):
                state.isLoading = false
                state.errorMessage = nil
                state.chatRoom = ChatRoomModel(room: room)
                return .none

            case let .chatRoomResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .messageHistoryResponse(isInitial, .success(page)):
                state.isMessagesLoading = false
                state.hasLoadedMessages = true
                state.nextCursor = page.nextCursor
                state.hasOlderMessages = page.hasNext
                mergeMessages(page.content, into: &state)
                if state.hasSubmittedApplication { return .none }
                guard isInitial, state.shouldRetryBookingCard else { return .none }
                state.shouldRetryBookingCard = false
                return .run { send in
                    try? await Task.sleep(for: .seconds(1))
                    await send(.retryBookingCard)
                }

            case let .messageHistoryResponse(_, .failure(error)):
                state.isMessagesLoading = false
                state.hasLoadedMessages = true
                state.errorMessage = error.localizedDescription
                return .none

            case let .missedMessagesResponse(.success(page)):
                mergeMessages(page.content, into: &state)
                return .none

            case let .missedMessagesResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .realtimeConnectionResponse(.success(stream)):
                return .run { send in
                    for await event in stream {
                        await send(.realtimeEvent(event))
                    }
                }
                .cancellable(id: EffectID.realtime, cancelInFlight: true)

            case let .realtimeConnectionResponse(.failure(error)):
                state.isRealtimeReady = false
                state.errorMessage = error.localizedDescription
                return .send(.delegate(.errorMessageRequested(error.localizedDescription)))

            case let .realtimeEvent(event):
                return handleRealtimeEvent(event, state: &state)

            case let .textSendResponse(clientMessageID, .failure(error)):
                if error as? ChatRealtimeError == .notReady {
                    updatePendingMessage(clientMessageID, in: &state) { message in
                        message.updating(deliveryStatus: .queued)
                    }
                    return .none
                }
                updatePendingMessage(clientMessageID, in: &state) { message in
                    message.updating(deliveryStatus: .failed)
                }
                state.errorMessage = error.localizedDescription
                return .send(.delegate(.errorMessageRequested(error.localizedDescription)))

            case .textSendResponse(_, .success):
                return .none

            case .loadPreviousMessages:
                guard state.hasOlderMessages, !state.isMessagesLoading, let cursor = state.nextCursor else { return .none }
                state.isMessagesLoading = true
                return fetchMessages(roomID: state.chatRoom.roomID, cursor: cursor, isInitial: false)

            case .retryBookingCard:
                guard !state.isMessagesLoading else { return .none }
                state.isMessagesLoading = true
                return fetchMessages(roomID: state.chatRoom.roomID, cursor: nil, isInitial: true)

            case .backButtonTapped:
                return .send(.delegate(.dismissRequested))

            case let .viewDetailsButtonTapped(listingID):
                return .send(
                    .delegate(
                        .listingDetailRequested(
                            listingID,
                            isApplicationDisabled: false
                        )
                    )
                )

            case .applicationBannerTapped:
                return .send(
                    .delegate(
                        .listingDetailRequested(
                            state.chatRoom.listingID,
                            isApplicationDisabled: false
                        )
                    )
                )

            case let .messageTextChanged(text):
                guard !state.chatRoom.isBlocked else { return .none }
                state.messageText = text
                return .none

            case let .keywordTapped(keyword):
                guard !state.chatRoom.isBlocked else { return .none }
                let message = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                return sendText(message, state: &state)

            case .sendButtonTapped:
                guard !state.chatRoom.isBlocked else { return .none }
                let message = state.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                state.messageText = ""
                return sendText(message, state: &state)

            case let .retryFailedMessageTapped(clientMessageID):
                return retryFailedMessage(clientMessageID, state: &state)

            case let .failedMessageDeleteButtonTapped(clientMessageID):
                guard state.messages.contains(where: {
                    $0.clientMessageID == clientMessageID && $0.deliveryStatus == .failed
                }) else { return .none }
                state.selectedFailedMessageID = clientMessageID
                return .none

            case .failedMessageDialogDismissed:
                state.selectedFailedMessageID = nil
                return .none

            case .selectedFailedMessageResendTapped:
                guard let clientMessageID = state.selectedFailedMessageID else { return .none }
                state.selectedFailedMessageID = nil
                return retryFailedMessage(clientMessageID, state: &state)

            case .selectedFailedMessageDeleteTapped:
                guard let clientMessageID = state.selectedFailedMessageID else { return .none }
                state.selectedFailedMessageID = nil
                state.messages.removeAll {
                    $0.clientMessageID == clientMessageID && $0.deliveryStatus == .failed
                }
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
}
