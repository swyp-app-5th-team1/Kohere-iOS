//
//  MockListingImageProvider.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import Foundation

enum MockListingImageProvider {
    nonisolated static func listingImageName(listingID: String, propertyType: String?) -> String {
        imageName(
            category: .listing,
            propertyType: propertyType,
            seed: listingID
        )
    }

    nonisolated static func listingImageNames(
        listingID: String,
        propertyType: String?,
        count: Int = 5
    ) -> [String] {
        imageNames(
            category: .listing,
            propertyType: propertyType,
            seed: listingID,
            count: count
        )
    }

    nonisolated static func roomImageName(listingID: String, roomOfferID: String, propertyType: String?) -> String {
        imageName(
            category: .room,
            propertyType: propertyType,
            seed: "\(listingID)-\(roomOfferID)"
        )
    }

    nonisolated static func roomImageNames(
        listingID: String,
        roomOfferID: String,
        propertyType: String?,
        count: Int = 4
    ) -> [String] {
        imageNames(
            category: .room,
            propertyType: propertyType,
            seed: "\(listingID)-\(roomOfferID)",
            count: count
        )
    }

    nonisolated private static func imageName(category: ImageCategory, propertyType: String?, seed: String) -> String {
        imageNames(category: category, propertyType: propertyType, seed: seed, count: 1)[0]
    }

    nonisolated private static func imageNames(
        category: ImageCategory,
        propertyType: String?,
        seed: String,
        count: Int
    ) -> [String] {
        let property = PropertyType(rawValue: propertyType, seed: seed)
        let imageCount = category.imageCount(for: property)
        let requestedCount = max(1, min(count, imageCount))
        let startIndex = Int(stableHash(seed) % UInt64(imageCount))

        return (0..<requestedCount).map { offset in
            let imageIndex = ((startIndex + offset) % imageCount) + 1
            return "\(category.assetPrefix)_\(property.assetPrefix)_\(String(format: "%02d", imageIndex))"
        }
    }

    nonisolated private static func stableHash(_ value: String) -> UInt64 {
        value.unicodeScalars.reduce(UInt64(5381)) { hash, scalar in
            ((hash << 5) &+ hash) &+ UInt64(scalar.value)
        }
    }
}

private extension MockListingImageProvider {
    enum ImageCategory {
        case listing
        case room

        nonisolated var assetPrefix: String {
            switch self {
            case .listing:
                return "listing"
            case .room:
                return "room"
            }
        }

        nonisolated func imageCount(for propertyType: PropertyType) -> Int {
            switch (self, propertyType) {
            case (.listing, .koliving):
                return 12
            case (.listing, .shareHouse):
                return 12
            case (.listing, .goshiwon):
                return 25
            case (.room, .koliving):
                return 25
            case (.room, .shareHouse):
                return 27
            case (.room, .goshiwon):
                return 50
            }
        }
    }

    enum PropertyType: CaseIterable {
        case koliving
        case shareHouse
        case goshiwon

        nonisolated init(rawValue: String?, seed: String) {
            let normalizedValue = rawValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: " ", with: "_")
                .uppercased()

            switch normalizedValue {
            case "CO_LIVING", "COLIVING", "KOLIVING":
                self = .koliving
            case "SHARE_HOUSE", "SHAREHOUSE":
                self = .shareHouse
            case "GOSHIWON":
                self = .goshiwon
            default:
                let types = Self.allCases
                self = types[Int(MockListingImageProvider.stableHash(seed) % UInt64(types.count))]
            }
        }

        nonisolated var assetPrefix: String {
            switch self {
            case .koliving:
                return "koliving"
            case .shareHouse:
                return "shareHouse"
            case .goshiwon:
                return "goshiwon"
            }
        }
    }
}
