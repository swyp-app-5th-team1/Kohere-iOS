//
//  PlaceSearchResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

nonisolated struct PlaceSearchResponseDTO: Decodable, Sendable {
    let items: [PlaceSearchItemResponseDTO]?
}

nonisolated struct PlaceSearchItemResponseDTO: Decodable, Sendable {
    let title: String?
    let address: String?
    let roadAddress: String?
    let lat: Double?
    let lng: Double?
}
