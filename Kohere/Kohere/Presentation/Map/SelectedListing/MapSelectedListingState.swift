//
//  MapSelectedListingState.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import ComposableArchitecture

extension MapFeature.State {
    var selectedListingItem: ListingItemModel? {
        guard let selectedMarkerID, selectedListingRequestID == nil else { return nil }
        guard let listing = selectedListing, listing.listingID == selectedMarkerID else {
            return listings.first { $0.listingID == selectedMarkerID }
        }

        @Dependency(\.convertMonthlyRentCurrencyUseCase)
        var convertCurrency
        var item = ListingItemModel(
            listing: listing,
            exchangeRate: krwToUSDExchangeRate,
            convertMonthlyRentCurrencyUseCase: convertCurrency,
            language: appLanguage
        )
        if let status = favoriteStatusesByListingID[selectedMarkerID] {
            item.isLiked = status.isFavorited
            item.favoriteCount = status.favoriteCount
        }
        return item
    }

    var selectedListingTitle: String {
        guard let selectedListingItem else { return "" }
        return selectedListingItem.title.isEmpty ? "제목 없음" : selectedListingItem.title
    }

    mutating func clearSelectedListing() {
        selectedMarkerID = nil
        selectedListing = nil
        selectedListingRequestID = nil
        sheetMode = .listingList
    }
}
