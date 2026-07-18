//
//  PlaceSearchRepository.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

actor PlaceSearchRepository: PlaceSearchInterface {
    private let networkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        networkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.networkService = networkService
        self.environmentProvider = environmentProvider
    }

    func searchPlaces(keyword: String) async throws -> [PlaceSearchResult] {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let environment = try environmentProvider()
        let queryDTO = PlaceSearchQueryDTO(keyword: query)
        let responseDTO: PlaceSearchResponseDTO = try await networkService.request(
            PlaceSearchRouter.search(query: queryDTO, environment)
        )

        return (responseDTO.items ?? []).compactMap { $0.toEntity() }
    }
}

extension PlaceSearchClient: DependencyKey {
    static let liveValue: PlaceSearchClient = {
        let repository: any PlaceSearchInterface = PlaceSearchRepository()
        return PlaceSearchClient(repository: repository)
    }()
}

private extension PlaceSearchItemResponseDTO {
    nonisolated func toEntity() -> PlaceSearchResult? {
        guard let coordinate else { return nil }

        let title = (title ?? "").naverPlainText
        guard !title.isEmpty else { return nil }

        return PlaceSearchResult(
            id: "\(lng ?? 0)-\(lat ?? 0)-\(title)",
            title: title,
            roadAddress: (roadAddress ?? "").naverPlainText,
            address: (address ?? "").naverPlainText,
            coordinate: coordinate
        )
    }

    nonisolated var coordinate: MapCoordinate? {
        guard let lat, let lng else { return nil }

        return MapCoordinate(latitude: lat, longitude: lng)
    }
}

private extension String {
    nonisolated var naverPlainText: String {
        let withoutTags = replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        return withoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
