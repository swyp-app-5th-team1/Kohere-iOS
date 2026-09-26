//
//  ChatResponseMapper.swift
//  Kohere
//
//  Created by Codex on 9/26/26.
//

import Foundation

extension ChatRoomPageResponseDTO {
    func toEntity() throws -> ChatRoomPage {
        ChatRoomPage(content: try content.map { try $0.toEntity() }, page: page.toEntity())
    }
}

extension ChatStompGuideResponseDTO {
    func toEntity() throws -> ChatStompGuide {
        guard let developmentURL = URL(string: developmentWebSocketUrl),
              let localURL = URL(string: localWebSocketUrl)
        else { throw DataError.invalidURL }

        return ChatStompGuide(
            developmentWebSocketURL: developmentURL,
            localWebSocketURL: localURL,
            webSocketEndpoint: webSocketEndpoint,
            connectHeaderName: connectHeaderName,
            connectHeaderValueFormat: connectHeaderValueFormat,
            controlQueue: controlQueue,
            ackQueue: ackQueue,
            errorQueue: errorQueue,
            roomEventQueue: roomEventQueue,
            translationQueue: translationQueue,
            controlSendDestination: controlSendDestination,
            roomSubscribeDestination: roomSubscribeDestination,
            messageSendDestination: messageSendDestination,
            maxTextCodePoints: maxTextCodePoints,
            heartbeatSeconds: heartbeatSeconds
        )
    }
}

extension ChatRoomResponseDTO {
    func toEntity() throws -> ChatRoom {
        guard let role = ChatRoomRole(rawValue: myRole) else { throw DataError.decodingFailed }
        return ChatRoom(roomID: chatRoomId, myRole: role, listing: listing.toEntity(),
                        counterpart: counterpart.toEntity(), isBlocked: blocked, lastMessage: lastMessage?.toEntity())
    }
}

extension ChatRoomListingResponseDTO {
    func toEntity() -> ChatRoomListing {
        ChatRoomListing(listingID: listingId, title: title, address: address)
    }
}

extension ChatRoomCounterpartResponseDTO {
    func toEntity() -> ChatRoomCounterpart {
        ChatRoomCounterpart(userID: userId, displayName: displayName)
    }
}

extension ChatRoomLastMessageResponseDTO {
    func toEntity() -> ChatRoomLastMessage {
        ChatRoomLastMessage(messageID: messageId, type: type.flatMap(ChatMessageType.init(rawValue:)),
                            preview: preview, sentAt: ChatDateParser.date(from: sentAt))
    }
}

extension ChatMessagePageResponseDTO {
    func toEntity() throws -> ChatMessagePage {
        ChatMessagePage(content: try content.map { try $0.toEntity() }, nextCursor: nextCursor, hasNext: hasNext)
    }
}

extension ChatMessageResponseDTO {
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

extension ChatInquiryCardResponseDTO {
    func toEntity() -> ChatInquiryCard {
        ChatInquiryCard(listingID: listingId, thumbnailURL: thumbnailUrl, title: title, city: city,
                        district: district, listingType: listingType, monthlyRentMin: monthlyRentMin,
                        monthlyRentMax: monthlyRentMax)
    }
}

extension ChatBookingCardResponseDTO {
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

extension ChatRoomReportResponseDTO {
    func toEntity() throws -> ChatReport {
        guard let reason = ChatReportReason(rawValue: reason),
              let receivedAt = ChatDateParser.date(from: receivedAt)
        else { throw DataError.decodingFailed }
        return ChatReport(reportID: reportId, roomID: chatRoomId, reason: reason,
                          status: status, receivedAt: receivedAt)
    }
}

enum ChatDateParser {
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
