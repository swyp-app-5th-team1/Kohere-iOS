//
//  ListingSearchInput.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

struct ListingSearchInput: Equatable {
    static let defaultPageSize = 10

    let bounds: MapBounds
    let page: Int
    let size: Int
    let sort: ListingSearchSort
    let minBudget: Int?
    let maxBudget: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let propertyTypes: [ListingSearchPropertyType]
    let conditions: [RoomCondition]
    let arcRequired: Bool?

    init(
        bounds: MapBounds,
        page: Int = 0,
        size: Int = Self.defaultPageSize,
        sort: ListingSearchSort = .recommended,
        minBudget: Int? = nil,
        maxBudget: Int? = nil,
        minDeposit: Int? = nil,
        maxDeposit: Int? = nil,
        propertyTypes: [ListingSearchPropertyType] = [],
        conditions: [RoomCondition] = [],
        arcRequired: Bool? = nil
    ) {
        self.bounds = bounds
        self.page = page
        self.size = size
        self.sort = sort
        self.minBudget = minBudget
        self.maxBudget = maxBudget
        self.minDeposit = minDeposit
        self.maxDeposit = maxDeposit
        self.propertyTypes = propertyTypes
        self.conditions = conditions
        self.arcRequired = arcRequired
    }
}

enum ListingSearchSort: String, Equatable {
    case recommended = "RECOMMENDED"
    case priceAscending = "PRICE_ASC"
    case distance = "DISTANCE"
}

enum ListingSearchPropertyType: String, Equatable {
    case goshiwon = "GOSHIWON"
    case coLiving = "CO_LIVING"
    case shareHouse = "SHARE_HOUSE"
}
