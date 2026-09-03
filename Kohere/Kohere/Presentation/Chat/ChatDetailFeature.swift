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

    private nonisolated enum CancelID { case realtime }

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
        var isMessagesLoading = false
        var hasLoadedMessages = false
        var nextCursor: String?
        var hasOlderMessages = false
        var shouldRetryBookingCard: Bool
        var showsInquiryCard: Bool
        var errorMessage: String?
        var isRealtimeReady = false
        var selectedFailedMessageID: UUID?

        var showsApplicationBanner: Bool {
            participantRole == .tenant && showsInquiryCard && hasLoadedMessages && !hasSubmittedApplication
        }

        var showsKeywordSuggestions: Bool {
            participantRole == .tenant
        }

        init(
            chatRoom: ChatRoomModel,
            participantRole: ChatRoomRole = .tenant,
            hasSubmittedApplication: Bool = false,
            messages: [ChatMessage] = [],
            shouldRetryBookingCard: Bool = false,
            showsInquiryCard: Bool = false
        ) {
            self.chatRoom = chatRoom
            self.participantRole = participantRole
            self.hasSubmittedApplication = hasSubmittedApplication
            self.messages = messages
            self.shouldRetryBookingCard = shouldRetryBookingCard
            self.showsInquiryCard = showsInquiryCard
        }
    }

    @CasePathable
    enum Delegate: Equatable {
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
                    .cancel(id: CancelID.realtime),
                    .run { _ in await disconnect() }
                )

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

            case let .messageHistoryResponse(isInitial, .success(page)):
                state.isMessagesLoading = false
                state.hasLoadedMessages = true
                state.nextCursor = page.nextCursor
                state.hasOlderMessages = page.hasNext
                mergeRealtimeHistory(page.content, into: &state)
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
                mergeRealtimeHistory(page.content, into: &state)
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
                .cancellable(id: CancelID.realtime, cancelInFlight: true)

            case let .realtimeConnectionResponse(.failure(error)):
                state.isRealtimeReady = false
                state.errorMessage = error.localizedDescription
                return .send(.delegate(.errorMessageRequested(error.localizedDescription)))

            case let .realtimeEvent(event):
                return handleRealtimeEvent(event, state: &state)

            case let .textSendResponse(clientMessageID, .failure(error)):
                if error as? ChatRealtimeError == .notReady {
                    updatePendingMessage(clientMessageID, in: &state) { message in
                        Self.message(message, deliveryStatus: .queued)
                    }
                    return .none
                }
                updatePendingMessage(clientMessageID, in: &state) { message in
                    Self.message(message, deliveryStatus: .failed)
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
                return .none

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

    private static func currentTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func localMessage(
        _ text: String,
        sender: ChatRoomRole,
        clientMessageID: UUID,
        deliveryStatus: ChatMessageDeliveryStatus
    ) -> ChatMessage {
        ChatMessage(id: "client-\(clientMessageID.uuidString)", sender: sender, originalText: text,
                    timeText: currentTimeText(), sentAt: Date(), clientMessageID: clientMessageID,
                    deliveryStatus: deliveryStatus)
    }

    private func fetchMessages(roomID: Int, cursor: String?, isInitial: Bool) -> Effect<Action> {
        let fetch = fetchChatMessagesUseCase
        return .run { send in
            do {
                let page = try await fetch.execute(roomID, cursor, nil, 30)
                await send(.messageHistoryResponse(isInitial: isInitial, .success(page)))
            } catch {
                await send(.messageHistoryResponse(isInitial: isInitial, .failure(error)))
            }
        }
    }

    private func fetchMissedMessages(roomID: Int, afterMessageID: Int?) -> Effect<Action> {
        let fetch = fetchChatMessagesUseCase
        return .run { send in
            do {
                let page = try await fetch.execute(roomID, nil, afterMessageID, 100)
                await send(.missedMessagesResponse(.success(page)))
            } catch {
                await send(.missedMessagesResponse(.failure(error)))
            }
        }
    }

    private func connectRealtime(roomID: Int) -> Effect<Action> {
        let connect = chatRealtimeClient.connect
        return .run { send in
            do {
                await send(.realtimeConnectionResponse(.success(try await connect(roomID))))
            } catch {
                await send(.realtimeConnectionResponse(.failure(error)))
            }
        }
    }

    private func sendText(_ text: String, state: inout State) -> Effect<Action> {
        let clientMessageID = UUID()
        let roomID = state.chatRoom.roomID
        let deliveryStatus: ChatMessageDeliveryStatus = state.isRealtimeReady ? .sending : .queued
        state.messages.append(
            Self.localMessage(
                text,
                sender: state.participantRole,
                clientMessageID: clientMessageID,
                deliveryStatus: deliveryStatus
            )
        )
        guard state.isRealtimeReady else { return .none }
        return sendPendingMessage(roomID: roomID, clientMessageID: clientMessageID, content: text)
    }

    private func sendPendingMessage(roomID: Int, clientMessageID: UUID, content: String) -> Effect<Action> {
        let send = chatRealtimeClient.sendText
        return .run { output in
            do {
                try await send(roomID, clientMessageID, content)
                await output(.textSendResponse(clientMessageID: clientMessageID, .success(())))
            } catch {
                await output(.textSendResponse(clientMessageID: clientMessageID, .failure(error)))
            }
        }
    }

    private func retryFailedMessage(_ clientMessageID: UUID, state: inout State) -> Effect<Action> {
        guard let index = state.messages.firstIndex(where: {
            $0.clientMessageID == clientMessageID && $0.deliveryStatus == .failed
        }) else { return .none }

        let message = state.messages[index]
        let deliveryStatus: ChatMessageDeliveryStatus = state.isRealtimeReady ? .sending : .queued
        state.messages[index] = Self.message(message, deliveryStatus: deliveryStatus)
        guard state.isRealtimeReady else { return .none }
        return sendPendingMessage(
            roomID: state.chatRoom.roomID,
            clientMessageID: clientMessageID,
            content: message.originalText
        )
    }

    private func handleRealtimeEvent(_ event: ChatRealtimeEvent, state: inout State) -> Effect<Action> {
        switch event {
        case let .connection(connection):
            state.isRealtimeReady = connection == .ready
            if connection == .disconnected {
                for index in state.messages.indices where state.messages[index].deliveryStatus == .sending {
                    state.messages[index] = Self.message(state.messages[index], deliveryStatus: .queued)
                }
                return .none
            }
            guard connection == .ready else { return .none }
            return resendQueuedMessages(state: &state)

        case let .subscriptionReady(subscription):
            guard subscription.roomID == state.chatRoom.roomID else { return .none }
            let lastConfirmedID = state.messages.compactMap(\.serverMessageID).max()
            return fetchMissedMessages(roomID: subscription.roomID, afterMessageID: lastConfirmedID)

        case let .acknowledgement(ack):
            state.messages.removeAll {
                $0.serverMessageID == ack.messageID && $0.clientMessageID != ack.clientMessageID
            }
            updatePendingMessage(ack.clientMessageID, in: &state) { message in
                Self.message(message, serverMessageID: ack.messageID, sentAt: ack.sentAt, deliveryStatus: .sent)
            }
            Self.sortMessages(&state.messages)
            return .none

        case let .sendFailure(failure):
            if let clientMessageID = failure.clientMessageID {
                updatePendingMessage(clientMessageID, in: &state) { message in
                    Self.message(message, deliveryStatus: .failed)
                }
            }
            state.errorMessage = failure.message
            return .send(.delegate(.errorMessageRequested(failure.message)))

        case let .translatedMessage(message):
            guard message.roomID == state.chatRoom.roomID,
                  !state.messages.contains(where: { $0.serverMessageID == message.messageID })
            else { return .none }
            let counterpartRole: ChatRoomRole = state.participantRole == .tenant ? .landlord : .tenant
            state.messages.append(
                ChatMessage(
                    id: "server-\(message.messageID)", sender: counterpartRole,
                    originalText: message.originalContent, translatedText: message.translatedContent,
                    timeText: Self.timeText(message.sentAt), sentAt: message.sentAt,
                    clientMessageID: message.clientMessageID, serverMessageID: message.messageID
                )
            )
            return .none

        case let .roomMessage(message):
            mergeRealtimeHistory([message], into: &state)
            return .none

        case .roomListChanged:
            return .none
        }
    }

    private func resendQueuedMessages(state: inout State) -> Effect<Action> {
        let roomID = state.chatRoom.roomID
        var effects: [Effect<Action>] = []
        for index in state.messages.indices where state.messages[index].deliveryStatus == .queued {
            let message = state.messages[index]
            guard let clientMessageID = message.clientMessageID else { continue }
            state.messages[index] = Self.message(message, deliveryStatus: .sending)
            effects.append(
                sendPendingMessage(
                    roomID: roomID,
                    clientMessageID: clientMessageID,
                    content: message.originalText
                )
            )
        }
        return .merge(effects)
    }

    private func mergeRealtimeHistory(_ messages: [StoredChatMessage], into state: inout State) {
        let newMessages = messages
            .filter { incoming in
                !state.messages.contains(where: { $0.serverMessageID == incoming.messageID })
            }
            .map { Self.message(from: $0, room: state.chatRoom, role: state.participantRole) }
        state.messages.append(contentsOf: newMessages)
        Self.sortMessages(&state.messages)
        if messages.contains(where: { $0.type == .bookingCard }) {
            state.hasSubmittedApplication = true
            state.shouldRetryBookingCard = false
        }
        if messages.contains(where: { $0.type == .inquiryCard }) {
            state.showsInquiryCard = true
        }
    }

    private static func sortMessages(_ messages: inout [ChatMessage]) {
        messages.sort {
            let leftDate = $0.sentAt ?? .distantPast
            let rightDate = $1.sentAt ?? .distantPast
            if leftDate != rightDate { return leftDate < rightDate }
            return ($0.serverMessageID ?? Int.max) < ($1.serverMessageID ?? Int.max)
        }
    }

    private func updatePendingMessage(
        _ clientMessageID: UUID,
        in state: inout State,
        update: (ChatMessage) -> ChatMessage
    ) {
        guard let index = state.messages.firstIndex(where: { $0.clientMessageID == clientMessageID }) else { return }
        state.messages[index] = update(state.messages[index])
    }

    private static func message(
        _ message: ChatMessage,
        serverMessageID: Int? = nil,
        sentAt: Date? = nil,
        deliveryStatus: ChatMessageDeliveryStatus
    ) -> ChatMessage {
        let resolvedDate = sentAt ?? message.sentAt
        let resolvedTimeText = resolvedDate.map { Self.timeText($0) } ?? message.timeText
        return ChatMessage(
            id: message.id, type: message.type, sender: message.sender, originalText: message.originalText,
            translatedText: message.translatedText,
            timeText: resolvedTimeText, sentAt: resolvedDate,
            inquiryCard: message.inquiryCard, bookingCard: message.bookingCard,
            clientMessageID: message.clientMessageID,
            serverMessageID: serverMessageID ?? message.serverMessageID,
            deliveryStatus: deliveryStatus
        )
    }

    private static func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func message(from message: StoredChatMessage, room: ChatRoomModel, role: ChatRoomRole) -> ChatMessage {
        let sender: ChatRoomRole = message.isMine ? role : (role == .tenant ? .landlord : .tenant)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let card = message.bookingCard.map { booking in
            ChatRoomModel(roomID: room.roomID, myRole: role,
                          listingID: booking.listing?.listingID ?? room.listingID,
                          listingName: booking.listing?.title ?? room.listingName,
                          location: booking.listing?.address ?? room.location,
                          counterpartName: room.counterpartName, thumbnailURL: booking.listing?.thumbnailURL,
                          createdAt: message.sentAt, applicantName: booking.applicant?.name ?? "N/A",
                          applicantGenderCode: booking.applicant?.gender ?? "",
                          applicantCountryCode: booking.applicant?.country ?? "",
                          applicantCountryName: booking.applicant?.countryName ?? "",
                          applicantEmail: booking.applicant?.email ?? "N/A",
                          roomType: booking.roomOfferName ?? "N/A", moveInDate: booking.moveInDate,
                          leaseTermMonths: booking.contractPeriod ?? 0, depositAmount: booking.deposit,
                          totalCostAmount: booking.totalAmount,
                          pricePerMonthAmount: booking.listing?.monthlyRent)
        }
        return ChatMessage(id: "server-\(message.messageID)", type: message.type, sender: sender,
                           originalText: message.originalContent ?? "", translatedText: message.translatedContent,
                           timeText: formatter.string(from: message.sentAt), sentAt: message.sentAt,
                           inquiryCard: message.inquiryCard, bookingCard: card,
                           serverMessageID: message.messageID)
    }
}
