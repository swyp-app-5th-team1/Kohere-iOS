//
//  ChatRoom.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import Foundation

struct ChatRoom: Equatable, Identifiable {
    let id: Int
    let listingName: String
    let regionName: String
    let accommodationType: String
    let status: String
    let lastMessageAt: Date
    let applicantName: String
    let moveInDate: Date
    let minStayMonths: Int
    let deposit: Int
    let totalCostKRW: Int
    let pricePerMonthKRW: Int
}
