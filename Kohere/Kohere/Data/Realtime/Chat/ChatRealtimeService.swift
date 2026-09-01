//
//  ChatRealtimeService.swift
//  Kohere
//
//  Created by soomin on 8/28/26.
//

import Combine
import Foundation
import OSLog
import SwiftStomp

@MainActor
final class ChatRealtimeService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Kohere", category: "ChatRealtime")
    private let chatRepository: ChatRepository
    private let accessTokenProvider: ChatAccessTokenProvider
    private let environmentProvider: () throws -> APIEnvironment

    private var stomp: SwiftStomp?
    private var guide: ChatStompGuide?
    private var roomID: Int?
    private var continuation: AsyncStream<ChatRealtimeEvent>.Continuation?
    private var cancellables: Set<AnyCancellable> = []
    private var reconnectTask: Task<Void, Never>?
    private var connectionID = UUID()
    private var isStopped = true
    private var isControlReady = false

    init(
        chatRepository: ChatRepository? = nil,
        keychainClient: KeychainClient? = nil,
        reissueToken: (@Sendable (_ refreshToken: String) async throws -> AuthToken)? = nil,
        environmentProvider: (() throws -> APIEnvironment)? = nil
    ) {
        self.chatRepository = chatRepository ?? ChatRepository()
        self.accessTokenProvider = ChatAccessTokenProvider(
            keychainClient: keychainClient ?? .liveValue,
            reissueToken: reissueToken ?? { try await ReissueTokenUseCase.liveValue.execute($0) }
        )
        self.environmentProvider = environmentProvider ?? { try APIEnvironment.live() }
    }

    func connect(roomID: Int) async throws -> AsyncStream<ChatRealtimeEvent> {
        await disconnect()

        let guide = try await chatRepository.fetchStompGuide()
        self.guide = guide
        self.roomID = roomID
        self.isStopped = false

        let stream = AsyncStream<ChatRealtimeEvent> { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in await self?.disconnect() }
            }
        }

        try await openConnection()
        return stream
    }

    func disconnect() async {
        isStopped = true
        isControlReady = false
        reconnectTask?.cancel()
        reconnectTask = nil
        connectionID = UUID()
        cancellables.removeAll()
        stomp?.disconnect(force: true)
        stomp = nil
        guide = nil
        roomID = nil
        continuation?.finish()
        continuation = nil
    }

    func sendText(roomID: Int, clientMessageID: UUID, content: String) async throws {
        guard let stomp, stomp.isConnected, isControlReady, let guide, self.roomID == roomID else {
            throw ChatRealtimeError.notReady
        }
        guard content.unicodeScalars.count <= guide.maxTextCodePoints else {
            throw ChatRealtimeError.messageTooLong(maximum: guide.maxTextCodePoints)
        }

        let payload = ChatTextSendDTO(clientMessageId: clientMessageID.uuidString, content: content)
        let data = try JSONEncoder().encode(payload)
        guard let body = String(data: data, encoding: .utf8) else {
            throw ChatRealtimeError.encodingFailed
        }
        let destination = guide.messageSendDestination.replacingOccurrences(of: "{roomId}", with: String(roomID))
        stomp.send(body: body, to: destination, headers: ["content-type": "application/json"])
    }

    private func openConnection() async throws {
        guard let guide, let roomID else { throw ChatRealtimeError.notReady }
        let accessToken = try await accessTokenProvider.validAccessToken()

        let webSocketURL = try resolvedWebSocketURL(guide: guide)
        let authorization = guide.connectHeaderValueFormat.replacingOccurrences(
            of: "{accessToken}",
            with: accessToken
        )
        let heartbeatMilliseconds = max(guide.heartbeatSeconds, 1) * 1_000
        let currentConnectionID = UUID()
        connectionID = currentConnectionID
        isControlReady = false

        let stomp = SwiftStomp(
            host: webSocketURL,
            headers: [
                guide.connectHeaderName: authorization,
                "heart-beat": "\(heartbeatMilliseconds),\(heartbeatMilliseconds)"
            ]
        )
        stomp.callbacksThread = .main
        self.stomp = stomp
        observe(stomp, connectionID: currentConnectionID, roomID: roomID)
        continuation?.yield(.connection(.connecting))
        stomp.connect(acceptVersion: "1.2", autoReconnect: false)
    }

    private func resolvedWebSocketURL(guide: ChatStompGuide) throws -> URL {
        let environment = try environmentProvider()
        guard var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: false) else {
            throw ChatRealtimeError.invalidWebSocketURL
        }
        components.scheme = components.scheme == "http" ? "ws" : "wss"
        components.path = guide.webSocketEndpoint
        components.query = nil
        components.fragment = nil
        guard let url = components.url else { throw ChatRealtimeError.invalidWebSocketURL }
        return url
    }

    private func observe(_ stomp: SwiftStomp, connectionID: UUID, roomID: Int) {
        cancellables.removeAll()

        stomp.eventsUpstream
            .sink { [weak self] event in
                guard let self, self.connectionID == connectionID else { return }
                handle(event, stomp: stomp, roomID: roomID)
            }
            .store(in: &cancellables)

        stomp.messagesUpstream
            .sink { [weak self] message in
                guard let self, self.connectionID == connectionID else { return }
                handle(message)
            }
            .store(in: &cancellables)
    }

    private func handle(_ event: StompUpstreamEvent, stomp: SwiftStomp, roomID: Int) {
        switch event {
        case let .connected(type):
            guard case .toStomp = type, let guide else { return }
            subscribe(using: stomp, guide: guide, roomID: roomID)
            stomp.enableAutoPing(pingInterval: TimeInterval(max(guide.heartbeatSeconds, 1)))

        case .disconnected:
            logger.warning("STOMP 연결 종료 roomID=\(roomID, privacy: .public)")
            isControlReady = false
            continuation?.yield(.connection(.disconnected))
            scheduleReconnect()

        case let .error(error):
            logger.error("STOMP 오류: \(error.localizedDescription, privacy: .public)")
            isControlReady = false
            continuation?.yield(.connection(.disconnected))
            scheduleReconnect()
        }
    }

    private func subscribe(using stomp: SwiftStomp, guide: ChatStompGuide, roomID: Int) {
        [guide.controlQueue, guide.ackQueue, guide.errorQueue, guide.roomEventQueue, guide.translationQueue]
            .forEach { stomp.subscribe(to: $0) }

        let roomDestination = guide.roomSubscribeDestination.replacingOccurrences(
            of: "{roomId}",
            with: String(roomID)
        )
        stomp.subscribe(to: roomDestination)

        let ping = ChatControlPingDTO(version: 1, requestId: UUID().uuidString)
        if let data = try? JSONEncoder().encode(ping), let body = String(data: data, encoding: .utf8) {
            stomp.send(body: body, to: guide.controlSendDestination, headers: ["content-type": "application/json"])
        }
    }

    private func scheduleReconnect() {
        guard !isStopped, reconnectTask == nil else { return }
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self, !self.isStopped else { return }
            reconnectTask = nil
            cancellables.removeAll()
            stomp?.disconnect(force: true)
            stomp = nil
            do {
                try await openConnection()
            } catch {
                scheduleReconnect()
            }
        }
    }

    private func handle(_ message: StompUpstreamMessage) {
        let body: Data
        let destination: String
        switch message {
        case let .text(text, _, value, _):
            body = Data(text.utf8)
            destination = value
        case let .data(data, _, value, _):
            body = data
            destination = value
        }
        guard let guide else { return }

        switch destination {
        case guide.controlQueue:
            handleControl(body)
        case guide.ackQueue:
            if let value = try? JSONDecoder.chat.decode(ChatTextAcknowledgementDTO.self, from: body),
               let event = value.toEntity() {
                continuation?.yield(.acknowledgement(event))
            }
        case guide.errorQueue:
            if let value = try? JSONDecoder.chat.decode(ChatTextFailureDTO.self, from: body) {
                continuation?.yield(.sendFailure(value.toEntity()))
            }
        case guide.translationQueue:
            if let value = try? JSONDecoder.chat.decode(ChatTranslatedMessageDTO.self, from: body),
               let event = value.toEntity() {
                continuation?.yield(.translatedMessage(event))
            }
        case guide.roomEventQueue:
            continuation?.yield(.roomListChanged)
        default:
            handleRoomMessage(body)
        }
    }

    private func handleControl(_ data: Data) {
        guard let control = try? JSONDecoder.chat.decode(ChatControlEventDTO.self, from: data) else { return }
        switch control.type {
        case "PONG":
            isControlReady = true
            continuation?.yield(.connection(.ready))
        case "SUBSCRIPTION_READY":
            guard let roomID = control.roomId else { return }
            continuation?.yield(.subscriptionReady(.init(roomID: roomID, highWatermark: control.highWatermark)))
        default:
            logger.warning("알 수 없는 STOMP control 이벤트: \(control.type, privacy: .public)")
            break
        }
    }

    private func handleRoomMessage(_ data: Data) {
        guard let value = try? JSONDecoder.chat.decode(ChatMessageResponseDTO.self, from: data),
              let event = value.toRealtimeEntity()
        else { return }
        continuation?.yield(.roomMessage(event))
    }
}

nonisolated enum ChatRealtimeError: LocalizedError, Equatable {
    case missingAccessToken
    case invalidWebSocketURL
    case notReady
    case messageTooLong(maximum: Int)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAccessToken: "로그인이 필요합니다."
        case .invalidWebSocketURL: "채팅 서버 주소가 올바르지 않습니다."
        case .notReady: "채팅 연결을 준비하고 있습니다. 잠시 후 다시 시도해 주세요."
        case let .messageTooLong(maximum): "메시지는 최대 \(maximum)자까지 입력할 수 있습니다."
        case .encodingFailed: "메시지를 전송할 수 없습니다."
        }
    }
}

private struct ChatTextSendDTO: Encodable {
    let clientMessageId: String
    let content: String
}

private struct ChatControlPingDTO: Encodable {
    let version: Int
    let requestId: String
}

private struct ChatControlEventDTO: Decodable {
    let type: String
    let roomId: Int?
    let highWatermark: Int?

    private enum CodingKeys: String, CodingKey {
        case type
        case event
        case eventType
        case command
        case roomId
        case highWatermark
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .event)
            ?? container.decodeIfPresent(String.self, forKey: .eventType)
            ?? container.decode(String.self, forKey: .command)
        roomId = try container.decodeIfPresent(Int.self, forKey: .roomId)
        highWatermark = try container.decodeIfPresent(Int.self, forKey: .highWatermark)
    }
}

private struct ChatTextAcknowledgementDTO: Decodable {
    let clientMessageId: String
    let messageId: Int
    let sentAt: Date
    let duplicate: Bool

    func toEntity() -> ChatTextAcknowledgement? {
        guard let clientMessageID = UUID(uuidString: clientMessageId) else { return nil }
        return .init(clientMessageID: clientMessageID, messageID: messageId, sentAt: sentAt, duplicate: duplicate)
    }
}

private struct ChatTextFailureDTO: Decodable {
    let clientMessageId: String?
    let code: String
    let message: String

    func toEntity() -> ChatTextFailure {
        .init(clientMessageID: clientMessageId.flatMap(UUID.init(uuidString:)), code: code, message: message)
    }
}

private struct ChatTranslatedMessageDTO: Decodable {
    let messageId: Int
    let clientMessageId: String?
    let chatRoomId: Int
    let senderId: Int
    let originalContent: String
    let translatedContent: String?
    let sentAt: Date

    func toEntity() -> ChatTranslatedMessage? {
        .init(messageID: messageId, clientMessageID: clientMessageId.flatMap(UUID.init(uuidString:)),
              roomID: chatRoomId, senderID: senderId, originalContent: originalContent,
              translatedContent: translatedContent, sentAt: sentAt)
    }
}

private extension JSONDecoder {
    static var chat: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.chatFractional.date(from: value)
                ?? ISO8601DateFormatter.chatStandard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
        }
        return decoder
    }
}

private extension ISO8601DateFormatter {
    static let chatFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let chatStandard = ISO8601DateFormatter()
}

private extension ChatMessageResponseDTO {
    func toRealtimeEntity() -> StoredChatMessage? {
        guard let messageType = ChatMessageType(rawValue: type),
              let date = ISO8601DateFormatter.chatFractional.date(from: sentAt)
                ?? ISO8601DateFormatter.chatStandard.date(from: sentAt)
        else { return nil }
        return StoredChatMessage(
            messageID: messageId,
            roomID: chatRoomId,
            type: messageType,
            isMine: mine,
            originalContent: originalContent,
            translatedContent: translation?.content,
            sentAt: date,
            inquiryCard: inquiryCard.map {
                .init(listingID: $0.listingId, thumbnailURL: $0.thumbnailUrl, title: $0.title,
                      city: $0.city, district: $0.district, listingType: $0.listingType,
                      monthlyRentMin: $0.monthlyRentMin, monthlyRentMax: $0.monthlyRentMax)
            },
            bookingCard: bookingCard.map {
                .init(bookingID: $0.bookingId, roomOfferID: $0.roomOfferId, roomOfferName: $0.roomOfferName,
                      moveInDate: $0.moveInDate.flatMap { value in
                          let formatter = DateFormatter()
                          formatter.locale = Locale(identifier: "en_US_POSIX")
                          formatter.dateFormat = "yyyy-MM-dd"
                          return formatter.date(from: value)
                      }, contractPeriod: $0.contractPeriod, deposit: $0.deposit, totalAmount: $0.totalAmount,
                      listing: $0.listing.map {
                          .init(listingID: $0.listingId, title: $0.title, address: $0.address,
                                monthlyRent: $0.monthlyRent, thumbnailURL: $0.thumbnailUrl)
                      },
                      applicant: $0.applicant.map {
                          .init(userID: $0.userId, name: $0.name, gender: $0.gender,
                                country: $0.country, countryName: $0.countryName, email: $0.email)
                      })
            }
        )
    }
}
