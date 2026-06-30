//
//  ChatRoomModel.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import Foundation

struct ChatRoomModel: Equatable, Identifiable {
    let id: Int
    let listingName: String
    let location: String
    let statusText: String
    let timeText: String
    let applicantName: String
    let moveInDate: String
    let leaseTerm: String
    let deposit: String
    let totalCost: String
    let pricePerMonth: String
    
    init(entity: ChatRoom) {
        self.id = entity.id
        self.listingName = entity.listingName
        self.location = "\(entity.regionName) · \(entity.accommodationType)"
        self.statusText = entity.status == "SUBMITTED" ? "Move-in request submitted" : "Request updated"
        self.timeText = "2분 전"
        self.applicantName = entity.applicantName
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        self.moveInDate = formatter.string(from: entity.moveInDate)
        
        self.leaseTerm = "\(entity.minStayMonths)-month"
        self.deposit = entity.deposit == 0 ? "N/A" : "₩ \(entity.deposit)"
        
        self.totalCost = "₩ \(entity.totalCostKRW)"
        self.pricePerMonth = "₩ \(entity.pricePerMonthKRW)/mo"
    }
}

extension ChatRoomModel {
    static let mockChatRooms: [ChatRoomModel] = [
        ChatRoomModel(
            entity: ChatRoom(
                id: 1, listingName: "Hongdae Studio share", regionName: "Seogyo-dong, Mapo-gu",
                accommodationType: "Co-living", status: "SUBMITTED", lastMessageAt: Date().addingTimeInterval(-120),
                applicantName: "Gil dong Hong", moveInDate: Date().addingTimeInterval(86400 * 14),
                minStayMonths: 3, deposit: 0, totalCostKRW: 1280000, pricePerMonthKRW: 420000
            )
        ),
        ChatRoomModel(
            entity: ChatRoom(
                id: 2, listingName: "Gangnam Premium Room", regionName: "Yeoksam-dong, Gangnam-gu",
                accommodationType: "Studio", status: "UPDATED", lastMessageAt: Date().addingTimeInterval(-600),
                applicantName: "John Doe", moveInDate: Date().addingTimeInterval(86400 * 30),
                minStayMonths: 6, deposit: 1000000, totalCostKRW: 2500000, pricePerMonthKRW: 850000
            )
        ),
        ChatRoomModel(
            entity: ChatRoom(
                id: 3, listingName: "Sinchon Cozy House", regionName: "Changcheon-dong, Seodaemun-gu",
                accommodationType: "Share house", status: "SUBMITTED", lastMessageAt: Date().addingTimeInterval(-3600),
                applicantName: "Minsoo Kim", moveInDate: Date().addingTimeInterval(86400 * 7),
                minStayMonths: 2, deposit: 0, totalCostKRW: 900000, pricePerMonthKRW: 450000
            )
        ),
        ChatRoomModel(
            entity: ChatRoom(
                id: 4, listingName: "Itaewon View Room", regionName: "Hannam-dong, Yongsan-gu",
                accommodationType: "Apartment", status: "UPDATED", lastMessageAt: Date().addingTimeInterval(-7200),
                applicantName: "Sarah Jenkins", moveInDate: Date().addingTimeInterval(86400 * 45),
                minStayMonths: 12, deposit: 3000000, totalCostKRW: 4800000, pricePerMonthKRW: 1200000
            )
        )
    ]
}
