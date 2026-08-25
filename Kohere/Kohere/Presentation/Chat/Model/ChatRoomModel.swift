//
//  ChatRoomModel.swift
//  Kohere
//
//  Created by soomin on 6/29/26.
//

import Foundation

nonisolated struct ChatRoomModel: Equatable, Identifiable {
    let roomID: Int
    let myRole: ChatRoomRole
    let listingID: String
    let listingName: String
    let location: String
    let counterpartName: String
    let isBlocked: Bool
    let lastMessageType: ChatMessageType?
    let lastMessagePreview: String?
    let thumbnailURL: String?
    let createdAt: Date?
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

    var id: Int { roomID }

    init(
        roomID: Int,
        myRole: ChatRoomRole = .tenant,
        listingID: String,
        listingName: String,
        location: String,
        counterpartName: String = "",
        isBlocked: Bool = false,
        lastMessageType: ChatMessageType? = nil,
        lastMessagePreview: String? = nil,
        thumbnailURL: String? = nil,
        createdAt: Date? = nil,
        applicantName: String = "N/A",
        applicantGenderCode: String = "",
        applicantCountryCode: String = "",
        applicantCountryName: String = "",
        applicantEmail: String = "N/A",
        roomType: String = "N/A",
        moveInDate: Date? = nil,
        leaseTermMonths: Int = 0,
        depositAmount: Int? = nil,
        totalCostAmount: Int? = nil,
        pricePerMonthAmount: Int? = nil
    ) {
        self.roomID = roomID
        self.myRole = myRole
        self.listingID = listingID
        self.listingName = listingName
        self.location = location
        self.counterpartName = counterpartName
        self.isBlocked = isBlocked
        self.lastMessageType = lastMessageType
        self.lastMessagePreview = lastMessagePreview
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.dateText = Self.dateText(createdAt)
        self.timeText = Self.timeText(createdAt)
        self.applicantName = applicantName
        self.applicantGenderCode = applicantGenderCode
        self.applicantCountryCode = applicantCountryCode
        self.applicantCountryName = applicantCountryName
        self.applicantEmail = applicantEmail
        self.roomType = roomType
        self.moveInDate = moveInDate
        self.leaseTermMonths = leaseTermMonths
        self.depositAmount = depositAmount
        self.totalCostAmount = totalCostAmount
        self.pricePerMonthAmount = pricePerMonthAmount
    }

    init(room: ChatRoom) {
        self.init(
            roomID: room.roomID,
            myRole: room.myRole,
            listingID: room.listing.listingID,
            listingName: room.listing.title,
            location: room.listing.address,
            counterpartName: room.counterpart.displayName,
            isBlocked: room.isBlocked,
            lastMessageType: room.lastMessage?.type,
            lastMessagePreview: room.lastMessage?.preview,
            createdAt: room.lastMessage?.sentAt,
            applicantName: Self.displayText(room.counterpart.displayName)
        )
    }

    private static func displayText(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "N/A" : trimmedValue
    }

    func localizedDateText(language: AppLanguage) -> String {
        guard let createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = language == .korean ? "yyyy.M.d E" : "M/d/yyyy EEE"
        return formatter.string(from: createdAt)
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
