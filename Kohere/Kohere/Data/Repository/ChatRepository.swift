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

private extension ChatMessagePageResponseDTO {
    func toEntity() throws -> ChatMessagePage {
        ChatMessagePage(content: try content.map { try $0.toEntity() }, nextCursor: nextCursor, hasNext: hasNext)
    }
}

private extension ChatMessageResponseDTO {
    func toEntity() throws -> StoredChatMessage {
        guard let messageType = ChatMessageType(rawValue: type),
              let date = ChatDateParser.date(from: sentAt)
        else { throw DataError.decodingFailed }
        return StoredChatMessage(messageID: messageId, roomID: chatRoomId, type: messageType, isMine: mine,
                                 originalContent: originalContent, translatedContent: translation?.content,
                                 sentAt: date, inquiryCard: inquiryCard?.toEntity(),
                                 bookingCard: bookingCard?.toEntity())
    }
}

private extension ChatInquiryCardResponseDTO {
    func toEntity() -> ChatInquiryCard {
        ChatInquiryCard(listingID: listingId, thumbnailURL: thumbnailUrl, title: title, city: city,
                        district: district, listingType: listingType, monthlyRentMin: monthlyRentMin,
                        monthlyRentMax: monthlyRentMax)
    }
}

private extension ChatBookingCardResponseDTO {
    func toEntity() -> ChatBookingCard {
        ChatBookingCard(bookingID: bookingId, roomOfferID: roomOfferId, roomOfferName: roomOfferName,
                        moveInDate: ChatDateParser.day(from: moveInDate), contractPeriod: contractPeriod,
                        deposit: deposit, totalAmount: totalAmount,
                        listing: listing.map {
                            ChatBookingListing(listingID: $0.listingId, title: $0.title, address: $0.address,
                                               monthlyRent: $0.monthlyRent, thumbnailURL: $0.thumbnailUrl)
                        },
                        applicant: applicant.map {
                            ChatBookingApplicant(userID: $0.userId, name: $0.name, gender: $0.gender,
                                                 country: $0.country, countryName: $0.countryName, email: $0.email)
                        })
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

    static func day(from value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
