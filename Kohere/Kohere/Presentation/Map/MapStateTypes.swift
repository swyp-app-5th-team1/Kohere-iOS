//
//  MapStateTypes.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

enum MapSheetMode: Equatable {
    case listingList
    case selectedListing
}

enum MapListingSource: Equatable {
    case idle
    case locationSearch
    case diagnosis
}

struct MapCameraMoveRequest: Equatable {
    let coordinate: MapCoordinate
    let targetPosition: MapCameraTargetPosition
}

enum MapCameraTargetPosition: Equatable {
    case center
    case upper
}
