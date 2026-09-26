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

    func fetchStompGuide() async throws -> ChatStompGuide {
        let environment = try environmentProvider()
        let response: ChatStompGuideResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.stompGuide(environment)
        )
        return try response.toEntity()
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

    func createInquiry(listingID: String) async throws -> ChatInquiry {
        let environment = try environmentProvider()
        let response: ChatInquiryResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.createInquiry(listingID: listingID, environment)
        )

        return ChatInquiry(roomID: response.chatRoomId, isCreated: response.created)
    }

    func fetchMessages(roomID: Int, cursor: String?, afterMessageID: Int?, size: Int) async throws -> ChatMessagePage {
        let environment = try environmentProvider()
        let query = ChatMessageHistoryQueryDTO(cursor: cursor, afterMessageID: afterMessageID, size: size)
        let response: ChatMessagePageResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.messageHistory(roomID: roomID, query: query, environment)
        )
        return try response.toEntity()
    }

    func hideRoom(roomID: Int) async throws {
        let environment = try environmentProvider()
        try await authenticatedNetworkService.requestVoid(ChatRouter.hideRoom(roomID: roomID, environment))
    }

    func blockRoom(roomID: Int) async throws {
        let environment = try environmentProvider()
        try await authenticatedNetworkService.requestVoid(ChatRouter.blockRoom(roomID: roomID, environment))
    }

    func reportRoom(roomID: Int, reason: ChatReportReason) async throws -> ChatReport {
        let environment = try environmentProvider()
        let request = ChatRoomReportRequestDTO(reason: reason.rawValue)
        let response: ChatRoomReportResponseDTO = try await authenticatedNetworkService.request(
            ChatRouter.reportRoom(roomID: roomID, request: request, environment)
        )
        return try response.toEntity()
    }
}

extension ChatClient: DependencyKey {
    static let liveValue = ChatClient(repository: ChatRepository())
}
