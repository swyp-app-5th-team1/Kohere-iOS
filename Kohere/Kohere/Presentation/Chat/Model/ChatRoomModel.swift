//
//  ChatRoomModel.swift
//  Kohere
//
//  Created by soomin on 6/29/26.
//

import Foundation

struct ChatRoomModel: Equatable, Identifiable {
    let id: Int
    let listingID: String
    let listingName: String
    let location: String
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

    init(
        id: Int,
        listingID: String,
        listingName: String,
        location: String,
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
        self.id = id
        self.listingID = listingID
        self.listingName = listingName
        self.location = location
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
    
    init(summary: BookingSummary) {
        self.id = summary.bookingID
        self.listingID = summary.listingID
        self.listingName = summary.title
        self.location = ""
        self.thumbnailURL = summary.thumbnailURL?.absoluteString
        self.createdAt = summary.createdAt
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
        self.listingID = detail.listingID
        self.listingName = detail.title
        self.location = detail.address
        self.thumbnailURL = detail.thumbnailURL?.absoluteString ?? fallback.thumbnailURL
        self.createdAt = detail.createdAt
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
