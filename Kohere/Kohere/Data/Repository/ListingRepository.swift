//
//  ListingRepository.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

final class ListingRepository: ListingInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = .authenticated(),
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

private extension ListingListItemResponseDTO {
    func toEntity() -> Listing? {
        guard let listingId else { return nil }

        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return Listing(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            minMonthlyRent: minMonthlyRent,
            maxMonthlyRent: maxMonthlyRent,
            minDeposit: minDeposit,
            maxDeposit: maxDeposit,
            minMaintenanceFee: minMaintenanceFee,
            maxMaintenanceFee: maxMaintenanceFee,
            minStayMonths: minStayMonths,
            maxStayMonths: maxStayMonths,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            address: address,
            nearestTransit: nearestTransit?.toEntity(),
            conditions: (conditions ?? []).compactMap(RoomCondition.init(conditionCode:)),
            distanceMeters: distanceMeters,
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount
        )
    }
}

private extension ListingFavoriteListItemResponseDTO {
    func toEntity() -> Listing? {
        guard let listingId else { return nil }

        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return Listing(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            minMonthlyRent: monthlyRent,
            maxMonthlyRent: monthlyRent,
            minDeposit: deposit,
            maxDeposit: deposit,
            minMaintenanceFee: maintenanceFee,
            maxMaintenanceFee: maintenanceFee,
            minStayMonths: nil,
            maxStayMonths: nil,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            address: address,
            nearestTransit: nil,
            conditions: (conditions ?? []).compactMap(RoomCondition.init(conditionCode:)),
            distanceMeters: nil,
            isFavorited: favorited ?? true,
            favoriteCount: favoriteCount
        )
    }
}

private extension ListingRecentListItemResponseDTO {
    func toEntity() -> Listing? {
        guard let listingId else { return nil }

        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return Listing(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            minMonthlyRent: minMonthlyRent,
            maxMonthlyRent: maxMonthlyRent,
            minDeposit: minDeposit,
            maxDeposit: maxDeposit,
            minMaintenanceFee: minMaintenanceFee,
            maxMaintenanceFee: maxMaintenanceFee,
            minStayMonths: minStayMonths,
            maxStayMonths: maxStayMonths,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            address: address,
            nearestTransit: nearestTransit?.toEntity(),
            conditions: (conditions ?? []).compactMap(RoomCondition.init(conditionCode:)),
            distanceMeters: distanceMeters,
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount
        )
    }
}

private extension ListingNearestTransitResponseDTO {
    func toEntity() -> ListingNearestTransit? {
        guard let type, let name else { return nil }

        return ListingNearestTransit(
            type: type,
            name: name,
            walkMinutes: walkMinutes
        )
    }
}

private extension ListingPageResponseDTO {
    func toEntity() -> ListingSearchPageInfo {
        let derivedHasNext: Bool?
        if let hasNext {
            derivedHasNext = hasNext
        } else if let last {
            derivedHasNext = !last
        } else if let number, let totalPages {
            derivedHasNext = number + 1 < totalPages
        } else {
            derivedHasNext = nil
        }

        return ListingSearchPageInfo(
            number: number,
            size: size,
            totalElements: totalElements,
            totalPages: totalPages,
            hasNext: derivedHasNext
        )
    }
}
