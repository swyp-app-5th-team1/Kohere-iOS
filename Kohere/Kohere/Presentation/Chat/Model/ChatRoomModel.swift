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
    let thumbnailURL: String?
    let dateText: String
    let timeText: String
    let applicantName: String
    let applicantGenderCode: String
    let applicantCountryCode: String
    let applicantCountryName: String
    let applicantEmail: String
    let roomType: String
    let moveInDate: Date?
    let leaseTermMonths: Int
    let depositAmount: Int?
    let totalCostAmount: Int?
    let pricePerMonthAmount: Int?
    
    init(entity: ChatRoom) {
        self.id = entity.id
        self.listingName = entity.listingName
        self.location = "\(entity.regionName) · \(entity.accommodationType)"
        self.thumbnailURL = MockListingImageProvider.listingImageName(
            listingID: "\(entity.id)",
            propertyType: entity.accommodationType
        )
        self.dateText = Self.dateText(entity.lastMessageAt)
        self.timeText = "2분 전"
        self.applicantName = entity.applicantName
        self.applicantGenderCode = Gender.male.rawValue
        self.applicantCountryCode = "DE"
        self.applicantCountryName = "Germany"
        self.applicantEmail = "kohere@gmail.com"
        self.roomType = "Room A"
        self.moveInDate = entity.moveInDate
        self.leaseTermMonths = entity.minStayMonths
        self.depositAmount = entity.deposit
        self.totalCostAmount = entity.totalCostKRW
        self.pricePerMonthAmount = entity.pricePerMonthKRW
    }
    
    init(summary: BookingSummary) {
        self.id = summary.bookingID
        self.listingName = summary.title
        self.location = ""
        self.thumbnailURL = summary.thumbnailURL?.absoluteString
            ?? MockListingImageProvider.listingImageName(
                listingID: summary.listingID,
                propertyType: nil
            )
        self.dateText = Self.dateText(summary.createdAt)
        self.timeText = Self.timeText(summary.createdAt)
        self.applicantName = "N/A"
        self.applicantGenderCode = ""
        self.applicantCountryCode = ""
        self.applicantCountryName = ""
        self.applicantEmail = "N/A"
        self.roomType = "N/A"
        self.moveInDate = summary.moveInDate
        self.leaseTermMonths = summary.contractPeriod
        self.depositAmount = nil
        self.totalCostAmount = nil
        self.pricePerMonthAmount = nil
    }
    
    init(detail: BookingDetail, fallback: ChatRoomModel) {
        self.id = detail.bookingID
        self.listingName = detail.title
        self.location = detail.address
        self.thumbnailURL = detail.thumbnailURL?.absoluteString ?? fallback.thumbnailURL
        self.dateText = Self.dateText(detail.createdAt)
        self.timeText = Self.timeText(detail.createdAt)
        self.applicantName = Self.displayText(detail.applicantName)
        self.applicantGenderCode = detail.applicantGender
        self.applicantCountryCode = detail.applicantCountry
        self.applicantCountryName = detail.applicantCountryName
        self.applicantEmail = Self.displayText(detail.applicantEmail)
        self.roomType = detail.roomOfferName.isEmpty ? "N/A" : detail.roomOfferName
        self.moveInDate = detail.moveInDate
        self.leaseTermMonths = detail.contractPeriod
        self.depositAmount = detail.deposit
        self.totalCostAmount = detail.totalAmount
        self.pricePerMonthAmount = fallback.pricePerMonthAmount
    }

    private static func displayText(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "N/A" : trimmedValue
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
