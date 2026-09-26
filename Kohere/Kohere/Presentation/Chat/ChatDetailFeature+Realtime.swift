//
//  ChatDetailFeature+Realtime.swift
//  Kohere
//
//  Created by Codex on 9/26/26.
//

import ComposableArchitecture

extension ChatDetailFeature {
    func connectRealtime(roomID: Int) -> Effect<Action> {
        let connect = chatRealtimeClient.connect
        return .run { send in
            do {
                await send(.realtimeConnectionResponse(.success(try await connect(roomID))))
            } catch {
                await send(.realtimeConnectionResponse(.failure(error)))
            }
        }
    }

    func handleRealtimeEvent(_ event: ChatRealtimeEvent, state: inout State) -> Effect<Action> {
        switch event {
        case let .connection(connection):
            state.isRealtimeReady = connection == .ready
            if connection == .disconnected {
                for index in state.messages.indices where state.messages[index].deliveryStatus == .sending {
                    state.messages[index] = state.messages[index].updating(deliveryStatus: .queued)
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
                message.updating(serverMessageID: ack.messageID, sentAt: ack.sentAt, deliveryStatus: .sent)
            }
            sortMessages(&state.messages)
            return .none

        case let .sendFailure(failure):
            if let clientMessageID = failure.clientMessageID {
                updatePendingMessage(clientMessageID, in: &state) { message in
                    message.updating(deliveryStatus: .failed)
                }
            }
            state.errorMessage = failure.message
            return .send(.delegate(.errorMessageRequested(failure.message)))

        case let .translatedMessage(message):
            guard message.roomID == state.chatRoom.roomID,
                  !state.messages.contains(where: { $0.serverMessageID == message.messageID })
            else { return .none }
            state.messages.append(
                ChatMessage(
                    id: "server-\(message.messageID)",
                    sender: state.participantRole.counterpart,
                    originalText: message.originalContent,
                    translatedText: message.translatedContent,
                    timeText: ChatTimestampFormatter.timeText(message.sentAt),
                    sentAt: message.sentAt,
                    clientMessageID: message.clientMessageID,
                    serverMessageID: message.messageID
                )
            )
            return .none

        case let .roomMessage(message):
            mergeMessages([message], into: &state)
            return .none

        case .roomListChanged:
            return .none
        }
    }

    func resendQueuedMessages(state: inout State) -> Effect<Action> {
        let roomID = state.chatRoom.roomID
        var effects: [Effect<Action>] = []
        for index in state.messages.indices where state.messages[index].deliveryStatus == .queued {
            let message = state.messages[index]
            guard let clientMessageID = message.clientMessageID else { continue }
            state.messages[index] = message.updating(deliveryStatus: .sending)
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
}
