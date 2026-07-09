//
//  BookingResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

struct BookingListResponseDTO: Decodable {
    let content: [BookingListItemResponseDTO]?
    let page: BookingPageResponseDTO?
}

struct BookingListItemResponseDTO: Decodable {
    let bookingId: Int?
    let listingId: String?
    let title: String?
    let thumbnailUrl: String?
    let roomOfferId: String?
    let moveInDate: String?
    let contractPeriod: Int?
    let status: String?
    let createdAt: String?
}

struct BookingDetailResponseDTO: Decodable {
    let bookingId: Int?
    let status: String?
    let listingId: String?
    let roomOfferId: String?
    let title: String?
    let thumbnailUrl: String?
    let address: String?
    let roomOfferName: String?
    let createdAt: String?
    let moveInDate: String?
    let contractPeriod: Int?
    let applicantName: String?
    let applicantGender: String?
    let applicantCountry: String?
    let applicantCountryName: String?
    let applicantEmail: String?
    let tenantName: String?
    let deposit: Int?
    let totalAmount: Int?
}

struct BookingPageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}
