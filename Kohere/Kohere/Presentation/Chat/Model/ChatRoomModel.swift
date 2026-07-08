//
//  ChatRoomModel.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import Foundation

nonisolated struct ChatRoomModel: Equatable, Identifiable {
    let id: Int
    let listingName: String
    let location: String
    let thumbnailURL: URL?
    let dateText: String
    let timeText: String
    let applicantName: String
    let applicantGender: String
    let applicantNationality: String
    let applicantEmail: String
    let roomType: String
    let moveInDate: String
    let leaseTerm: String
    let deposit: String
    let totalCost: String
    let pricePerMonth: String
    
    init(entity: ChatRoom) {
        self.id = entity.id
        self.listingName = entity.listingName
        self.location = "\(entity.regionName) · \(entity.accommodationType)"
        self.thumbnailURL = nil
        self.dateText = Self.dateText(entity.lastMessageAt)
        self.timeText = "2분 전"
        self.applicantName = entity.applicantName
        self.applicantGender = "Male"
        self.applicantNationality = "Germany"
        self.applicantEmail = "kohere@gmail.com"
        self.roomType = "Room A"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        self.moveInDate = formatter.string(from: entity.moveInDate)
        
        self.leaseTerm = "\(entity.minStayMonths)-month"
        self.deposit = entity.deposit == 0 ? "N/A" : Self.wonText(entity.deposit)
        
        self.totalCost = Self.wonText(entity.totalCostKRW)
        self.pricePerMonth = "\(Self.wonText(entity.pricePerMonthKRW))/mo"
    }
    
    init(summary: BookingSummary) {
        self.id = summary.bookingID
        self.listingName = summary.title
        self.location = ""
        self.thumbnailURL = summary.thumbnailURL
        self.dateText = Self.dateText(summary.createdAt)
        self.timeText = Self.timeText(summary.createdAt)
        self.applicantName = "N/A"
        self.applicantGender = "N/A"
        self.applicantNationality = "N/A"
        self.applicantEmail = "N/A"
        self.roomType = "N/A"
        self.moveInDate = Self.moveInDateText(summary.moveInDate)
        self.leaseTerm = Self.leaseTermText(summary.contractPeriod)
        self.deposit = "N/A"
        self.totalCost = "N/A"
        self.pricePerMonth = ""
    }
    
    init(detail: BookingDetail, fallback: ChatRoomModel) {
        self.id = detail.bookingID
        self.listingName = detail.title
        self.location = detail.address
        self.thumbnailURL = detail.thumbnailURL ?? fallback.thumbnailURL
        self.dateText = Self.dateText(detail.createdAt)
        self.timeText = Self.timeText(detail.createdAt)
        self.applicantName = detail.tenantName.isEmpty ? "N/A" : detail.tenantName
        self.applicantGender = "N/A"
        self.applicantNationality = "N/A"
        self.applicantEmail = "N/A"
        self.roomType = detail.roomOfferName.isEmpty ? "N/A" : detail.roomOfferName
        self.moveInDate = Self.moveInDateText(detail.moveInDate)
        self.leaseTerm = Self.leaseTermText(detail.contractPeriod)
        self.deposit = detail.deposit == 0 ? "N/A" : Self.wonText(detail.deposit)
        self.totalCost = Self.wonText(detail.totalAmount)
        self.pricePerMonth = fallback.pricePerMonth
    }
    
    private static func wonText(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        return "₩ \(formatter.string(from: NSNumber(value: value)) ?? "\(value)")"
    }
    
    private static func dateText(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy EEE"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: date)
    }
    
    private static func timeText(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return formatter.string(from: date)
    }
    
    private static func moveInDateText(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: date)
    }
    
    private static func leaseTermText(_ months: Int) -> String {
        guard months > 0 else { return "N/A" }
        return "\(months)-month"
    }
}

extension ChatRoomModel {
    static let mockChatRooms: [ChatRoomModel] = [
        ChatRoomModel(
            entity: ChatRoom(
                id: 1, listingName: "Hongdae Studio share", regionName: "Seogyo-dong, Mapo-gu",
                accommodationType: "Co-living", status: "SUBMITTED", lastMessageAt: Date().addingTimeInterval(-120),
                applicantName: "Gil dong Hong", moveInDate: Date().addingTimeInterval(86400 * 14),
                minStayMonths: 3, deposit: 0, totalCostKRW: 1260000, pricePerMonthKRW: 420000
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
