//
//  MapStateTypes.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

enum MapLocationAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum MapSheetMode: Equatable {
    case listingList
    case selectedListing
}

enum MapListingSource: Equatable {
    case idle
    case locationSearch
    case diagnosis
}
