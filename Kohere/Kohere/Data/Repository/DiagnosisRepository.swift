//
//  DiagnosisRepository.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

final class DiagnosisRepository: DiagnosisInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = .authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchDetail(diagnosisID: Int) async throws -> DiagnosisDetail {
        let environment = try environmentProvider()
        let responseDTO: DiagnosisDetailResponseDTO = try await authenticatedNetworkService.request(
            DiagnosisRouter.detail(diagnosisID: diagnosisID, environment)
        )

        return responseDTO.toEntity()
    }

    func fetchRecommendations(diagnosisID: Int) async throws -> DiagnosisRecommendations {
        let environment = try environmentProvider()
        let queryDTO = DiagnosisRecommendationsQueryDTO(
            page: 0,
            size: 20,
            sort: nil
        )
        let responseDTO: DiagnosisRecommendationsResponseDTO = try await authenticatedNetworkService.request(
            DiagnosisRouter.recommendations(
                diagnosisID: diagnosisID,
                query: queryDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }
}

extension DiagnosisClient: DependencyKey {
    static let liveValue: DiagnosisClient = {
        let repository: any DiagnosisInterface = DiagnosisRepository()
        return DiagnosisClient(repository: repository)
    }()
}

private extension DiagnosisDetailResponseDTO {
    func toEntity() -> DiagnosisDetail {
        DiagnosisDetail(
            diagnosisID: diagnosisId,
            region: region,
            purpose: purpose,
            university: university,
            district: district,
            conditions: conditions.compactMap(RoomCondition.init(rawValue:)),
            monthlyRentMin: monthlyRentMin,
            monthlyRentMax: monthlyRentMax,
            arcStatus: arcStatus,
            status: status,
            submittedAt: submittedAt
        )
    }
}

private extension DiagnosisRecommendationsResponseDTO {
    func toEntity() -> DiagnosisRecommendations {
        let listingEntities = (content ?? []).map { $0.toEntity() }
        let markerEntities = (markers ?? []).compactMap { $0.toEntity() }
        let fallbackMarkers = listingEntities.compactMap { listing -> MapMarkerItem? in
            guard let coordinate = listing.coordinate else { return nil }
            return MapMarkerItem(id: listing.listingID, coordinate: coordinate)
        }

        return DiagnosisRecommendations(
            listings: listingEntities,
            markers: markerEntities.isEmpty ? fallbackMarkers : markerEntities
        )
    }
}

private extension DiagnosisRecommendedListingResponseDTO {
    func toEntity() -> DiagnosisRecommendedListing {
        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return DiagnosisRecommendedListing(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            monthlyRent: monthlyRent,
            deposit: deposit,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            conditions: (conditions ?? []).compactMap(RoomCondition.init(rawValue:))
        )
    }
}

private extension DiagnosisRecommendationMarkerResponseDTO {
    func toEntity() -> MapMarkerItem? {
        guard let lat, let lng else { return nil }
        return MapMarkerItem(
            id: listingId,
            coordinate: MapCoordinate(latitude: lat, longitude: lng)
        )
    }
}
