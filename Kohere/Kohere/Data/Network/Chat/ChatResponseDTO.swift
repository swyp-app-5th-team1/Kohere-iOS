//
//  ChatResponseDTO.swift
//  Kohere
//
//  Created by soomin on 8/25/26.
//

struct ChatRoomPageResponseDTO: Decodable {
    let page: PageResponseDTO
    let content: [ChatRoomResponseDTO]
}

struct ChatRoomResponseDTO: Decodable {
    let chatRoomId: Int
    let myRole: String
    let blocked: Bool
    let counterpart: ChatRoomCounterpartResponseDTO
    let listing: ChatRoomListingResponseDTO
    let lastMessage: ChatRoomLastMessageResponseDTO?
}

struct ChatRoomCounterpartResponseDTO: Decodable {
    let userId: Int
    let displayName: String
}

struct ChatRoomListingResponseDTO: Decodable {
    let listingId: String
    let title: String
    let address: String
}

struct ChatRoomLastMessageResponseDTO: Decodable {
    let messageId: Int?
    let type: String?
    let preview: String?
    let sentAt: String?
}

struct ChatInquiryResponseDTO: Decodable {
    let chatRoomId: Int
    let created: Bool
}

struct ChatRoomReportResponseDTO: Decodable {
    let reportId: Int
    let chatRoomId: Int
    let reason: String
    let status: String
    let receivedAt: String
}

struct ChatMessagePageResponseDTO: Decodable {
    let content: [ChatMessageResponseDTO]
    let nextCursor: String?
    let hasNext: Bool
}

struct ChatMessageResponseDTO: Decodable {
    let messageId: Int
    let chatRoomId: Int
    let type: String
    let mine: Bool
    let originalContent: String?
    let sentAt: String
    let translation: ChatTranslationResponseDTO?
    let inquiryCard: ChatInquiryCardResponseDTO?
    let bookingCard: ChatBookingCardResponseDTO?
}

struct ChatInquiryCardResponseDTO: Decodable {
    let listingId: String
    let thumbnailUrl: String?
    let title: String
    let city: String
    let district: String
    let listingType: String
    let monthlyRentMin: Int
    let monthlyRentMax: Int
}

struct ChatTranslationResponseDTO: Decodable { let content: String? }

struct ChatBookingCardResponseDTO: Decodable {
    let bookingId: Int?
    let roomOfferId: String?
    let roomOfferName: String?
    let moveInDate: String?
    let contractPeriod: Int?
    let deposit: Int?
    let totalAmount: Int?
    let listing: ChatBookingListingResponseDTO?
    let applicant: ChatBookingApplicantResponseDTO?
}

struct ChatBookingListingResponseDTO: Decodable {
    let listingId: String?
    let title: String?
    let address: String?
    let monthlyRent: Int?
    let thumbnailUrl: String?
}

struct ChatBookingApplicantResponseDTO: Decodable {
    let userId: Int?
    let name: String?
    let gender: String?
    let country: String?
    let countryName: String?
    let email: String?
}
