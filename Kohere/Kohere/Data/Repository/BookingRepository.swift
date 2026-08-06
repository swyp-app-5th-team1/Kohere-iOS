//
//  BookingRepository.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

final class BookingRepository: BookingInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment
    
    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }
    
    func fetchBookings(page: Int, size: Int) async throws -> BookingPage {
        let environment = try environmentProvider()
        let queryDTO = BookingListQueryDTO(page: page, size: size)
        let responseDTO: BookingListResponseDTO = try await authenticatedNetworkService.request(
            BookingRouter.list(query: queryDTO, environment)
        )
        
        return responseDTO.toEntity()
    }
    
    func fetchBookingDetail(bookingID: Int) async throws -> BookingDetail {
        let environment = try environmentProvider()
        let responseDTO: BookingDetailResponseDTO = try await authenticatedNetworkService.request(
            BookingRouter.detail(bookingID: bookingID, environment)
        )
        
        return try responseDTO.toEntity()
    }

    func mutateBooking(_ mutation: BookingMutation, bookingID: Int) async throws {
        let environment = try environmentProvider()
        let router: BookingRouter

        switch mutation {
        case .report:
            router = .report(bookingID: bookingID, environment)
        case .block:
            router = .block(bookingID: bookingID, environment)
        case .delete:
            router = .delete(bookingID: bookingID, environment)
        }

        try await authenticatedNetworkService.requestVoid(router)
    }
}

extension BookingClient: DependencyKey {
    static let liveValue: BookingClient = {
        let repository: any BookingInterface = BookingRepository()
        return BookingClient(repository: repository)
    }()
}

private extension BookingListResponseDTO {
    func toEntity() -> BookingPage {
        BookingPage(
            content: (content ?? []).compactMap { $0.toEntity() },
            page: page?.toEntity()
        )
    }
}

private extension BookingListItemResponseDTO {
    func toEntity() -> BookingSummary? {
        guard let bookingId else { return nil }
        
        return BookingSummary(
            bookingID: bookingId,
            listingID: listingId ?? "",
            title: title ?? "",
            thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
            roomOfferID: roomOfferId ?? "",
            moveInDate: DateParser.dateOnly(from: moveInDate),
            contractPeriod: contractPeriod ?? 0,
            status: status ?? "",
            createdAt: DateParser.iso8601(from: createdAt)
        )
    }
}

private extension BookingDetailResponseDTO {
    func toEntity() throws -> BookingDetail {
        guard let bookingId else { throw DataError.decodingFailed }
        
        return BookingDetail(
            bookingID: bookingId,
            status: status ?? "",
            listingID: listingId ?? "",
            roomOfferID: roomOfferId ?? "",
            title: title ?? "",
            thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
            address: address ?? "",
            roomOfferName: roomOfferName ?? "",
            createdAt: DateParser.iso8601(from: createdAt),
            moveInDate: DateParser.dateOnly(from: moveInDate),
            contractPeriod: contractPeriod ?? 0,
            applicantName: applicantName ?? tenantName ?? "",
            applicantGender: applicantGender ?? "",
            applicantCountry: applicantCountry ?? "",
            applicantCountryName: applicantCountryName ?? "",
            applicantEmail: applicantEmail ?? "",
            tenantName: tenantName ?? applicantName ?? "",
            deposit: deposit ?? 0,
            totalAmount: totalAmount ?? 0
        )
    }
}

private enum DateParser {
    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static func iso8601(from value: String?) -> Date? {
        guard let value else { return nil }
        return iso8601WithFractionalSeconds.date(from: value) ?? iso8601.date(from: value)
    }
    
    static func dateOnly(from value: String?) -> Date? {
        guard let value else { return nil }
        return dateOnlyFormatter.date(from: value)
    }
}
