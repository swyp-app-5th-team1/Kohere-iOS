//
//  PlaceSearchResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

nonisolated struct PlaceSearchResponseDTO: Decodable, Sendable {
    let total: Int?
    let start: Int?
    let display: Int?
    let items: [PlaceSearchItemResponseDTO]?
}

nonisolated struct PlaceSearchItemResponseDTO: Decodable, Sendable {
    let title: String?
    let link: String?
    let category: String?
    let description: String?
    let telephone: String?
    let address: String?
    let roadAddress: String?
    let mapx: String?
    let mapy: String?

    enum CodingKeys: String, CodingKey {
        case title
        case link
        case category
        case description
        case telephone
        case address
        case roadAddress
        case mapx
        case mapy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodePlaceSearchStringIfPresent(forKey: .title)
        link = try container.decodePlaceSearchStringIfPresent(forKey: .link)
        category = try container.decodePlaceSearchStringIfPresent(forKey: .category)
        description = try container.decodePlaceSearchStringIfPresent(forKey: .description)
        telephone = try container.decodePlaceSearchStringIfPresent(forKey: .telephone)
        address = try container.decodePlaceSearchStringIfPresent(forKey: .address)
        roadAddress = try container.decodePlaceSearchStringIfPresent(forKey: .roadAddress)
        mapx = try container.decodePlaceSearchStringIfPresent(forKey: .mapx)
        mapy = try container.decodePlaceSearchStringIfPresent(forKey: .mapy)
    }
}

nonisolated struct PlaceSearchErrorResponseDTO: Decodable, Sendable {
    let errorMessage: String?
    let errorCode: String?
}

private extension KeyedDecodingContainer {
    nonisolated func decodePlaceSearchStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try decodeIfPresent(String.self, forKey: key) {
            return value
        }

        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }

        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }

        return nil
    }
}
