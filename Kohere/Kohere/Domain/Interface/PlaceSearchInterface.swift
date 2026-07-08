//
//  PlaceSearchInterface.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

protocol PlaceSearchInterface: Sendable {
    func searchPlaces(keyword: String) async throws -> [PlaceSearchResult]
}

struct PlaceSearchClient: Sendable {
    var searchPlaces: @Sendable (_ keyword: String) async throws -> [PlaceSearchResult]
}

extension PlaceSearchClient {
    init(repository: any PlaceSearchInterface) {
        self.init(
            searchPlaces: { keyword in
                try await repository.searchPlaces(keyword: keyword)
            }
        )
    }
}

extension DependencyValues {
    var placeSearchClient: PlaceSearchClient {
        get { self[PlaceSearchClient.self] }
        set { self[PlaceSearchClient.self] = newValue }
    }
}
