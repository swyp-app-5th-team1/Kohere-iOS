//
//  ListingRepository.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture
import Foundation

final class ListingRepository: ListingInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchListings(input: ListingSearchInput) async throws -> ListingSearchPage {
        let environment = try environmentProvider()
        let queryDTO = ListingListQueryDTO(input)
        let responseDTO: ListingListResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.list(query: queryDTO, environment)
        )

        return responseDTO.toEntity()
    }

    func fetchDetail(listingID: String) async throws -> ListingDetail {
        let environment = try environmentProvider()
        let responseDTO: ListingDetailResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.detail(listingID: listingID, environment)
        )

        return try responseDTO.toEntity()
    }

    func fetchFavoriteListings(page: Int, size: Int) async throws -> ListingSearchPage {
        let environment = try environmentProvider()
        let queryDTO = ListingFavoriteListQueryDTO(page: page, size: size)
        let responseDTO: ListingFavoriteListResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.favoriteList(query: queryDTO, environment)
        )

        return responseDTO.toEntity()
    }

    func fetchRecentListings() async throws -> [Listing] {
        let environment = try environmentProvider()
        let responseDTO: ListingRecentListResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.recentList(environment)
        )

        return responseDTO.toEntity()
    }

    func addFavorite(listingID: String) async throws -> ListingFavoriteStatus {
        let environment = try environmentProvider()
        let responseDTO: ListingFavoriteStatusResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.addFavorite(listingID: listingID, environment)
        )

        return responseDTO.toEntity()
    }

    func removeFavorite(listingID: String) async throws -> ListingFavoriteStatus {
        let environment = try environmentProvider()
        let responseDTO: ListingFavoriteStatusResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.removeFavorite(listingID: listingID, environment)
        )

        return responseDTO.toEntity()
    }

    func createBooking(listingID: String, input: ListingBookingCreateInput) async throws -> ListingBooking {
        let environment = try environmentProvider()
        let requestDTO = ListingBookingCreateRequestDTO(input)
        let responseDTO: ListingBookingResponseDTO = try await authenticatedNetworkService.request(
            ListingRouter.createBooking(listingID: listingID, request: requestDTO, environment)
        )

        return try responseDTO.toEntity()
    }
}

extension ListingClient: DependencyKey {
    static let liveValue: ListingClient = {
        let repository: any ListingInterface = ListingRepository()
        return ListingClient(repository: repository)
    }()
}

private extension ListingListResponseDTO {
    func toEntity() -> ListingSearchPage {
        ListingSearchPage(
            content: (content ?? []).compactMap { $0.toEntity() },
            page: page?.toEntity()
        )
    }
}

private extension ListingFavoriteListResponseDTO {
    func toEntity() -> ListingSearchPage {
        ListingSearchPage(
            content: (content ?? []).compactMap { $0.toEntity() },
            page: page?.toEntity()
        )
    }
}

private extension ListingRecentListResponseDTO {
    func toEntity() -> [Listing] {
        (content ?? []).compactMap { $0.toEntity() }
    }
}

private extension ListingFavoriteStatusResponseDTO {
    func toEntity() -> ListingFavoriteStatus {
        ListingFavoriteStatus(
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount ?? 0
        )
    }
}

private extension ListingBookingResponseDTO {
    func toEntity() throws -> ListingBooking {
        guard let bookingId,
              let status,
              let listingId,
              let roomOfferId,
              let moveInDate,
              let contractPeriod,
              let createdAt
        else {
            throw DataError.decodingFailed
        }

        return ListingBooking(
            bookingID: bookingId,
            status: status,
            listingID: listingId,
            roomOfferID: roomOfferId,
            moveInDate: moveInDate,
            contractPeriod: contractPeriod,
            createdAt: createdAt
        )
    }
}

private extension ListingListItemResponseDTO {
    func toEntity() -> Listing? {
        guard let listingId else { return nil }
        let propertyTypeLabel = type?.label ?? ""

        let coordinate: MapCoordinate?
        if let lat = location?.lat, let lng = location?.lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        let pricings = (roomOffers ?? []).compactMap(\.pricing)
        let monthlyRents = pricings.compactMap(\.monthlyRent)
        let deposits = pricings.compactMap(\.deposit)
        let maintenanceFees = pricings.compactMap(\.maintenanceFee)

        return Listing(
            listingID: listingId,
            title: title ?? "",
            type: propertyTypeLabel,
            minMonthlyRent: monthlyRents.min(),
            maxMonthlyRent: monthlyRents.max(),
            minDeposit: deposits.min(),
            maxDeposit: deposits.max(),
            minMaintenanceFee: maintenanceFees.min(),
            maxMaintenanceFee: maintenanceFees.max(),
            minStayMonths: contract?.minStayMonths,
            maxStayMonths: contract?.maxStayMonths,
            thumbnailURL: firstImageURL(imageUrls),
            coordinate: coordinate,
            address: address?.fullAddress,
            nearestTransit: nearestTransit?.toEntity(),
            distanceMeters: distanceMeters,
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount
        )
    }
}

private extension ListingItemV2ResponseDTO {
    func toEntity() -> Listing? {
        guard let listingId else { return nil }

        let coordinate: MapCoordinate?
        if let lat = location?.lat, let lng = location?.lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        let offers = roomOffers ?? []
        let pricings = offers.compactMap(\.pricing)
        let monthlyRents = pricings.compactMap(\.monthlyRent)
        let deposits = pricings.compactMap(\.deposit)
        let maintenanceFees = pricings.compactMap(\.maintenanceFee)
        let contracts = offers.compactMap(\.contract)

        return Listing(
            listingID: listingId,
            title: title ?? "",
            type: type?.label ?? "",
            minMonthlyRent: monthlyRents.min(),
            maxMonthlyRent: monthlyRents.max(),
            minDeposit: deposits.min(),
            maxDeposit: deposits.max(),
            minMaintenanceFee: maintenanceFees.min(),
            maxMaintenanceFee: maintenanceFees.max(),
            minStayMonths: contracts.compactMap(\.minStayMonths).min(),
            maxStayMonths: contracts.compactMap(\.maxStayMonths).max(),
            thumbnailURL: firstImageURL(imageUrls),
            coordinate: coordinate,
            address: address?.fullAddress,
            nearestTransit: nearestTransit?.toEntity(),
            distanceMeters: nil,
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount
        )
    }
}

private func firstImageURL(_ imageURLs: [String]?) -> String? {
    imageURLs?
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }
}

private extension ListingNearestTransitResponseDTO {
    func toEntity() -> ListingNearestTransit? {
        guard let type = type?.code, let name else { return nil }

        return ListingNearestTransit(
            type: type,
            name: name,
            walkMinutes: walkMinutes
        )
    }
}
