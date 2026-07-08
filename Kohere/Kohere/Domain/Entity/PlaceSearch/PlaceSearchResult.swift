//
//  PlaceSearchResult.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

nonisolated struct PlaceSearchResult: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let roadAddress: String
    let address: String
    let coordinate: MapCoordinate

    var displayAddress: String {
        roadAddress.isEmpty ? address : roadAddress
    }
}
