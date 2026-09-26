//
//  ChatDetailFeature+Message.swift
//  Kohere
//
//  Created by Codex on 9/26/26.
//

import ComposableArchitecture
import Foundation

extension ChatDetailFeature {
    func fetchMessages(roomID: Int, cursor: String?, isInitial: Bool) -> Effect<Action> {
        let fetch = fetchChatMessagesUseCase
        return .run { send in
            do {
                let page = try await fetch.execute(roomID, cursor, nil, 30)
                await send(.messageHistoryResponse(isInitial: isInitial, .success(page)))
            } catch {
                await send(.messageHistoryResponse(isInitial: isInitial, .failure(error)))
            }
        }
        .cancellable(id: EffectID.messages, cancelInFlight: isInitial)
    }

    func fetchMissedMessages(roomID: Int, afterMessageID: Int?) -> Effect<Action> {
        let fetch = fetchChatMessagesUseCase
        return .run { send in
            do {
                let page = try await fetch.execute(roomID, nil, afterMessageID, 100)
                await send(.missedMessagesResponse(.success(page)))
            } catch {
                await send(.missedMessagesResponse(.failure(error)))
            }
        }
        .cancellable(id: EffectID.missedMessages, cancelInFlight: true)
    }

    func sendText(_ text: String, state: inout State) -> Effect<Action> {
        let clientMessageID = uuid()
        let deliveryStatus: ChatMessageDeliveryStatus = state.isRealtimeReady ? .sending : .queued
        let sentAt = now
        state.messages.append(
            ChatMessage(
                id: "client-\(clientMessageID.uuidString)",
                sender: state.participantRole,
                originalText: text,
                timeText: ChatTimestampFormatter.timeText(sentAt),
                sentAt: sentAt,
                clientMessageID: clientMessageID,
                deliveryStatus: deliveryStatus
            )
        )
        guard state.isRealtimeReady else { return .none }
        return sendPendingMessage(
            roomID: state.chatRoom.roomID,
            clientMessageID: clientMessageID,
            content: text
        )
    }

    func sendPendingMessage(roomID: Int, clientMessageID: UUID, content: String) -> Effect<Action> {
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

    func retryFailedMessage(_ clientMessageID: UUID, state: inout State) -> Effect<Action> {
        guard let index = state.messages.firstIndex(where: {
            $0.clientMessageID == clientMessageID && $0.deliveryStatus == .failed
        }) else { return .none }

        let message = state.messages[index]
        let deliveryStatus: ChatMessageDeliveryStatus = state.isRealtimeReady ? .sending : .queued
        state.messages[index] = message.updating(deliveryStatus: deliveryStatus)
        guard state.isRealtimeReady else { return .none }
        return sendPendingMessage(
            roomID: state.chatRoom.roomID,
            clientMessageID: clientMessageID,
            content: message.originalText
        )
    }

    func mergeMessages(_ messages: [StoredChatMessage], into state: inout State) {
        let newMessages = messages
            .filter { incoming in
                !state.messages.contains(where: { $0.serverMessageID == incoming.messageID })
            }
            .map { ChatMessage(storedMessage: $0, room: state.chatRoom) }
        state.messages.append(contentsOf: newMessages)
        sortMessages(&state.messages)

        if messages.contains(where: { $0.type == .bookingCard }) {
            state.hasSubmittedApplication = true
            state.shouldRetryBookingCard = false
        }
        if messages.contains(where: { $0.type == .inquiryCard }) {
            state.showsInquiryCard = true
        }
    }

    func sortMessages(_ messages: inout [ChatMessage]) {
        messages.sort {
            let leftDate = $0.sentAt ?? .distantPast
            let rightDate = $1.sentAt ?? .distantPast
            if leftDate != rightDate { return leftDate < rightDate }
            return ($0.serverMessageID ?? Int.max) < ($1.serverMessageID ?? Int.max)
        }
    }

    func updatePendingMessage(
        _ clientMessageID: UUID,
        in state: inout State,
        update: (ChatMessage) -> ChatMessage
    ) {
        guard let index = state.messages.firstIndex(where: { $0.clientMessageID == clientMessageID }) else { return }
        state.messages[index] = update(state.messages[index])
    }
}
