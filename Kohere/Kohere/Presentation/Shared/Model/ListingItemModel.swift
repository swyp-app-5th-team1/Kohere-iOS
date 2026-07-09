//
//  ListingItemModel.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import Foundation

struct ListingItemModel: Equatable, Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String?
    let formattedPrice: String
    let formattedUsdPrice: String
    let detailsDescription: String
    let locationDescription: String
    let typeTag: String
    let period: String
    var isLiked: Bool
    var favoriteCount: Int?

    var listingID: String { id }

    nonisolated init(
        id: String,
        title: String = "",
        thumbnailURL: String? = nil,
        formattedPrice: String,
        formattedUsdPrice: String,
        detailsDescription: String,
        locationDescription: String,
        typeTag: String,
        period: String,
        isLiked: Bool,
        favoriteCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.formattedPrice = formattedPrice
        self.formattedUsdPrice = formattedUsdPrice
        self.detailsDescription = detailsDescription
        self.locationDescription = locationDescription
        self.typeTag = typeTag
        self.period = period
        self.isLiked = isLiked
        self.favoriteCount = favoriteCount
    }

    nonisolated init(
        id: Int,
        title: String = "",
        thumbnailURL: String? = nil,
        formattedPrice: String,
        formattedUsdPrice: String,
        detailsDescription: String,
        locationDescription: String,
        typeTag: String,
        period: String,
        isLiked: Bool,
        favoriteCount: Int? = nil
    ) {
        self.init(
            id: "\(id)",
            title: title,
            thumbnailURL: thumbnailURL,
            formattedPrice: formattedPrice,
            formattedUsdPrice: formattedUsdPrice,
            detailsDescription: detailsDescription,
            locationDescription: locationDescription,
            typeTag: typeTag,
            period: period,
            isLiked: isLiked,
            favoriteCount: favoriteCount
        )
    }
}
