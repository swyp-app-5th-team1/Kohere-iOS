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

private extension ListingListItemResponseDTO {
    func toEntity() -> ListingSearchListing? {
        guard let listingId else { return nil }

        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return ListingSearchListing(
            listingID: listingId,
            roomOfferID: roomOfferId ?? "",
            roomOfferName: roomOfferName ?? "",
            title: title ?? roomOfferName ?? "",
            type: type ?? "",
            monthlyRent: monthlyRent,
            deposit: deposit,
            maintenanceFee: maintenanceFee,
            availableCount: availableCount,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            address: address,
            conditions: (conditions ?? []).compactMap(RoomCondition.init(rawValue:)),
            distanceMeters: distanceMeters
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
