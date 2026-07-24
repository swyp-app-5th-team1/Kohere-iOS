//
//  ListingRequestDTO.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import Foundation

nonisolated struct ListingListQueryDTO {
    let swLat: Double
    let swLng: Double
    let neLat: Double
    let neLng: Double
    let minBudget: Int?
    let maxBudget: Int?
    let minDeposit: Int?
    let maxDeposit: Int?
    let type: [String]
    let conditions: [String]
    let arcRequired: Bool?
    let sort: String
    let page: Int
    let size: Int
}

struct ListingFavoriteListQueryDTO {
    let page: Int
    let size: Int
}

nonisolated struct ListingBookingCreateRequestDTO: Encodable, Sendable {
    let roomOfferId: String
    let moveInDate: String
    let contractPeriod: Int

    init(_ input: ListingBookingCreateInput) {
        roomOfferId = input.roomOfferID
        moveInDate = Self.moveInDateFormatter.string(from: input.moveInDate)
        contractPeriod = input.contractPeriod
    }

    private static var moveInDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

extension ListingListQueryDTO {
    nonisolated init(_ input: ListingSearchInput) {
        self.init(
            swLat: input.bounds.southWest.latitude,
            swLng: input.bounds.southWest.longitude,
            neLat: input.bounds.northEast.latitude,
            neLng: input.bounds.northEast.longitude,
            minBudget: input.minBudget,
            maxBudget: input.maxBudget,
            minDeposit: input.minDeposit,
            maxDeposit: input.maxDeposit,
            type: input.propertyTypes.map(\.rawValue),
            conditions: input.conditions.map(\.conditionCode),
            arcRequired: input.arcRequired,
            sort: input.sort.rawValue,
            page: input.page,
            size: input.size
        )
    }

    nonisolated var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "swLat", value: String(swLat)),
            URLQueryItem(name: "swLng", value: String(swLng)),
            URLQueryItem(name: "neLat", value: String(neLat)),
            URLQueryItem(name: "neLng", value: String(neLng)),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]

        append(&items, name: "minBudget", value: minBudget)
        append(&items, name: "maxBudget", value: maxBudget)
        append(&items, name: "minDeposit", value: minDeposit)
        append(&items, name: "maxDeposit", value: maxDeposit)
        append(&items, name: "arcRequired", value: arcRequired)

        type.forEach {
            items.append(URLQueryItem(name: "type", value: $0))
        }

        conditions.forEach {
            items.append(URLQueryItem(name: "conditions", value: $0))
        }

        return items
    }

    nonisolated private func append(
        _ items: inout [URLQueryItem],
        name: String,
        value: Int?
    ) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    nonisolated private func append(
        _ items: inout [URLQueryItem],
        name: String,
        value: Bool?
    ) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }
}

extension ListingFavoriteListQueryDTO {
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
    }
}
