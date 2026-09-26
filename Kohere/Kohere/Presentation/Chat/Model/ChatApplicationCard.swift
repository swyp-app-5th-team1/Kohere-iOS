//
//  ChatApplicationCard.swift
//  Kohere
//
//  Created by Codex on 9/26/26.
//

import Foundation

nonisolated struct ChatApplicationCard: Equatable {
    let listingID: String
    let listingName: String
    let location: String
    let thumbnailURL: String?
    let sentAt: Date
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

    var timeText: String {
        ChatTimestampFormatter.timeText(sentAt)
    }

    init(
        listingID: String,
        listingName: String,
        location: String,
        thumbnailURL: String? = nil,
        sentAt: Date,
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
        self.listingID = listingID
        self.listingName = listingName
        self.location = location
        self.thumbnailURL = thumbnailURL
        self.sentAt = sentAt
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

    init(booking: ChatBookingCard, room: ChatRoomModel, sentAt: Date) {
        self.listingID = booking.listing?.listingID ?? room.listingID
        self.listingName = booking.listing?.title ?? room.listingName
        self.location = booking.listing?.address ?? room.location
        self.thumbnailURL = booking.listing?.thumbnailURL
        self.sentAt = sentAt
        self.applicantName = booking.applicant?.name ?? "N/A"
        self.applicantGenderCode = booking.applicant?.gender ?? ""
        self.applicantCountryCode = booking.applicant?.country ?? ""
        self.applicantCountryName = booking.applicant?.countryName ?? ""
        self.applicantEmail = booking.applicant?.email ?? "N/A"
        self.roomType = booking.roomOfferName ?? "N/A"
        self.moveInDate = booking.moveInDate
        self.leaseTermMonths = booking.contractPeriod ?? 0
        self.depositAmount = booking.deposit
        self.totalCostAmount = booking.totalAmount
        self.pricePerMonthAmount = booking.listing?.monthlyRent
    }
}
