//
//  MapSelectedListingState.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

extension MapFeature.State {
    var selectedListingItem: ListingItemModel? {
        guard let selectedMarkerID else { return nil }
        return listings.first { $0.listingID == selectedMarkerID }
    }

    var selectedListingTitle: String {
        guard let selectedListingItem else { return "" }
        return selectedListingItem.title.isEmpty ? "제목 없음" : selectedListingItem.title
    }
}
