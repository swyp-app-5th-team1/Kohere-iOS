//
//  Listing.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

struct Listing: Equatable, Identifiable {
    let id: Int
    let minPriceKRW: Int
    let maxPriceKRW: Int
    let priceUSD: Int
    let deposit: Int
    let maintenanceFee: Int
    let distanceToStationMinutes: Int
    let stationName: String
    let accommodationType: String
    let minStayMonths: Int
    var isLiked: Bool
}
