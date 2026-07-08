//
//  PlaceSearchRequestDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

nonisolated struct PlaceSearchQueryDTO: Encodable, Sendable {
    let query: String
    let display: Int
    let start: Int
    let sort: String

    init(
        query: String,
        display: Int = 5,
        start: Int = 1,
        sort: String = "random"
    ) {
        self.query = query
        self.display = min(max(display, 1), 5)
        self.start = start
        self.sort = sort
    }
}
