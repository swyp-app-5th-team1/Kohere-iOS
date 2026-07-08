//
//  PlaceSearchRepository.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

actor PlaceSearchRepository: PlaceSearchInterface {
    private let networkService: ExternalNetworkService
    private let credentialProvider: @Sendable () throws -> PlaceSearchCredential

    fileprivate init(
        networkService: ExternalNetworkService = ExternalNetworkService(
            errorParser: PlaceSearchRepository.parsePlaceSearchError(from:)
        ),
        credentialProvider: @escaping @Sendable () throws -> PlaceSearchCredential = {
            try PlaceSearchCredential.live()
        }
    ) {
        self.networkService = networkService
        self.credentialProvider = credentialProvider
    }

    func searchPlaces(keyword: String) async throws -> [PlaceSearchResult] {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let credential = try credentialProvider()
        let queryDTO = PlaceSearchQueryDTO(query: query)
        let responseDTO: PlaceSearchResponseDTO = try await networkService.request(
            PlaceSearchRouter.localSearch(
                query: queryDTO,
                clientID: credential.clientID,
                clientSecret: credential.clientSecret
            )
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

private extension PlaceSearchRepository {
    nonisolated static func parsePlaceSearchError(from data: Data) -> DataError? {
        guard !data.isEmpty else { return nil }
        guard let errorResponse = try? JSONDecoder().decode(PlaceSearchErrorResponseDTO.self, from: data) else {
            return nil
        }

        guard errorResponse.errorMessage != nil || errorResponse.errorCode != nil else {
            return nil
        }

        return .serverError(
            code: errorResponse.errorCode ?? "PLACE_SEARCH_ERROR",
            message: errorResponse.errorMessage ?? "장소 검색 요청이 실패했습니다."
        )
    }

    nonisolated struct PlaceSearchCredential: Sendable {
        let clientID: String
        let clientSecret: String

        static func live(bundle: Bundle = .main) throws -> PlaceSearchCredential {
            guard
                let clientID = configValue(forKey: "NAVER_SEARCH_CLIENT_ID", bundle: bundle),
                let clientSecret = configValue(forKey: "NAVER_SEARCH_CLIENT_SECRET", bundle: bundle)
            else {
                throw DataError.missingNaverSearchCredentials
            }

            return PlaceSearchCredential(clientID: clientID, clientSecret: clientSecret)
        }

        private static func configValue(forKey key: String, bundle: Bundle) -> String? {
            guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
                return nil
            }

            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard
                !value.isEmpty,
                value != "$(\(key))",
                !value.hasPrefix("YOUR_")
            else {
                return nil
            }

            return value
        }
    }
}

private extension PlaceSearchItemResponseDTO {
    nonisolated func toEntity() -> PlaceSearchResult? {
        guard let coordinate else { return nil }

        let title = (title ?? "").naverPlainText
        guard !title.isEmpty else { return nil }

        return PlaceSearchResult(
            id: "\(mapx ?? "")-\(mapy ?? "")-\(title)",
            title: title,
            roadAddress: (roadAddress ?? "").naverPlainText,
            address: (address ?? "").naverPlainText,
            coordinate: coordinate
        )
    }

    nonisolated var coordinate: MapCoordinate? {
        guard
            let longitude = mapx?.naverCoordinateValue,
            let latitude = mapy?.naverCoordinateValue
        else {
            return nil
        }

        return MapCoordinate(latitude: latitude, longitude: longitude)
    }
}

private extension String {
    nonisolated var naverCoordinateValue: Double? {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rawValue = Double(trimmedValue) else { return nil }

        if abs(rawValue) > 180 {
            return rawValue / 10_000_000
        }

        return rawValue
    }

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
