//
//  ChatRoom.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

import Foundation

nonisolated enum ChatRoomRole: String, Equatable, Sendable {
    case tenant = "TENANT"
    case landlord = "LANDLORD"

    init?(userType: UserType) {
        switch userType {
        case .tenant:
            self = .tenant
        case .landlord:
            self = .landlord
        case .unknown:
            return nil
        }
    }
}

nonisolated struct ChatRoom: Equatable, Identifiable, Sendable {
    let roomID: Int
    let myRole: ChatRoomRole
    let listing: ChatRoomListing
    let counterpart: ChatRoomCounterpart
    let isBlocked: Bool
    let lastMessage: ChatRoomLastMessage?

    var id: Int { roomID }
}

nonisolated struct ChatRoomPage: Equatable, Sendable {
    let content: [ChatRoom]
    let page: PageInfo
}

nonisolated struct ChatRoomLastMessage: Equatable, Sendable {
    let messageID: Int?
    let type: ChatMessageType?
    let preview: String?
    let sentAt: Date?
}

nonisolated enum ChatMessageType: String, Equatable, Sendable {
    case text = "TEXT"
    case bookingCard = "BOOKING_CARD"
}

nonisolated struct ChatRoomListing: Equatable, Sendable {
    let listingID: String
    let title: String
    let address: String
}

nonisolated struct ChatRoomCounterpart: Equatable, Sendable {
    let userID: Int
    let displayName: String
}

nonisolated struct ChatInquiry: Equatable, Sendable {
    let roomID: Int
    let isCreated: Bool
}

nonisolated enum ChatReportReason: String, CaseIterable, Equatable, Sendable {
    case abuseHarassmentDiscrimination = "ABUSE_HARASSMENT_DISCRIMINATION"
    case illegalContent = "ILLEGAL_CONTENT"
    case sexualInappropriateContent = "SEXUAL_INAPPROPRIATE_CONTENT"
    case personalInformation = "PERSONAL_INFORMATION"
    case spam = "SPAM"
    case other = "OTHER"
}

nonisolated struct ChatReport: Equatable, Sendable {
    let reportID: Int
    let roomID: Int
    let reason: ChatReportReason
    let status: String
    let receivedAt: Date
}

nonisolated struct ChatMessagePage: Equatable, Sendable {
    let content: [StoredChatMessage]
    let nextCursor: String?
    let hasNext: Bool
}

nonisolated struct StoredChatMessage: Equatable, Identifiable, Sendable {
    let messageID: Int
    let roomID: Int
    let type: ChatMessageType
    let isMine: Bool
    let originalContent: String?
    let translatedContent: String?
    let sentAt: Date
    let bookingCard: ChatBookingCard?

    var id: Int { messageID }
}

nonisolated struct ChatBookingCard: Equatable, Sendable {
    let bookingID: Int?
    let roomOfferID: String?
    let roomOfferName: String?
    let moveInDate: Date?
    let contractPeriod: Int?
    let deposit: Int?
    let totalAmount: Int?
    let listing: ChatBookingListing?
    let applicant: ChatBookingApplicant?
}

nonisolated struct ChatBookingListing: Equatable, Sendable {
    let listingID: String?
    let title: String?
    let address: String?
    let monthlyRent: Int?
    let thumbnailURL: String?
}

nonisolated struct ChatBookingApplicant: Equatable, Sendable {
    let userID: Int?
    let name: String?
    let gender: String?
    let country: String?
    let countryName: String?
    let email: String?
}
