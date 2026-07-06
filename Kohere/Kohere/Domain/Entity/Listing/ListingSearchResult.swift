//
//  ListingSearchResult.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

struct ListingSearchPage: Equatable {
    let content: [Listing]
    let page: ListingSearchPageInfo?
}

struct ListingSearchPageInfo: Equatable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}
