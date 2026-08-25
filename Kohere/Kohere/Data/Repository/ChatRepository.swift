//
//  ChatRepository.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import ComposableArchitecture
import Foundation

final class ChatRepository: ChatInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchChatRooms(page: Int, size: Int) async throws -> ChatRoomPage {
        let environment = try environmentProvider()
        let query = ChatRoomListQueryDTO(page: page, size: size)
        let response: ChatRoomPageResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.roomList(query: query, environment)
        )

        return try response.toEntity()
    }

    func fetchChatRoom(roomID: Int) async throws -> ChatRoom {
        let environment = try environmentProvider()
        let response: ChatRoomResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.roomDetail(roomID: roomID, environment)
        )

        return try response.toEntity()
    }
}

extension ChatClient: DependencyKey {
    static let liveValue = ChatClient(repository: ChatRepository())
}

private extension ChatRoomPageResponseDTO {
    func toEntity() throws -> ChatRoomPage {
        ChatRoomPage(content: try content.map { try $0.toEntity() },
                     page: page.toEntity())
    }
}

private extension ChatRoomResponseDTO {
    func toEntity() throws -> ChatRoom {
        guard let role = ChatRoomRole(rawValue: myRole) else {
            throw DataError.decodingFailed
        }

        return ChatRoom(roomID: chatRoomId, myRole: role, listing: listing.toEntity(),
                        counterpart: counterpart.toEntity(), isBlocked: blocked, lastMessage: lastMessage?.toEntity())
    }
}

private extension ChatRoomListingResponseDTO {
    func toEntity() -> ChatRoomListing {
        ChatRoomListing(listingID: listingId, title: title, address: address)
    }
}

private extension ChatRoomCounterpartResponseDTO {
    func toEntity() -> ChatRoomCounterpart {
        ChatRoomCounterpart(userID: userId, displayName: displayName)
    }
}

private extension ChatRoomLastMessageResponseDTO {
    func toEntity() -> ChatRoomLastMessage {
        ChatRoomLastMessage(messageID: messageId, type: type.flatMap(ChatMessageType.init(rawValue:)),
                            preview: preview, sentAt: ChatDateParser.date(from: sentAt))
    }
}

private enum ChatDateParser {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func date(from value: String?) -> Date? {
        guard let value else { return nil }
        return withFractionalSeconds.date(from: value) ?? standard.date(from: value)
    }
}
