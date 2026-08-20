//
//  ChatApplicationCardFormatter.swift
//  Kohere
//
//  Created by soomin on 7/18/26.
//

import Foundation

struct ChatApplicationCardFormatter {
    let item: ChatRoomModel
    let language: AppLanguage

    var applicantName: String {
        displayText(item.applicantName)
    }

    var applicantGender: String {
        let genderCode = item.applicantGenderCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        switch genderCode {
        case Gender.male.rawValue:
            return localized("chat.applicationCard.value.gender.male")
        case Gender.female.rawValue:
            return localized("chat.applicationCard.value.gender.female")
        default:
            return displayText(item.applicantGenderCode)
        }
    }

    var applicantNationality: String {
        let countryCode = item.applicantCountryCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        if language == .korean,
           !countryCode.isEmpty,
           let localizedCountry = locale.localizedString(forRegionCode: countryCode) {
            return localizedCountry
        }

        let countryName = item.applicantCountryName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !countryName.isEmpty {
            return countryName
        }

        if !countryCode.isEmpty,
           let localizedCountry = locale.localizedString(forRegionCode: countryCode) {
            return localizedCountry
        }

        return notAvailable
    }

    var applicantEmail: String {
        displayText(item.applicantEmail)
    }

    var roomType: String {
        displayText(item.roomType)
    }

    var moveInDate: String {
        guard let moveInDate = item.moveInDate else { return notAvailable }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = language == .korean ? "yyyy.MM.dd" : "MMM d, yyyy"
        return formatter.string(from: moveInDate)
    }

    var leaseTerm: String {
        guard item.leaseTermMonths > 0 else { return notAvailable }
        return String(
            format: localized("chat.applicationCard.value.leaseTerm"),
            item.leaseTermMonths
        )
    }

    var deposit: String {
        guard let depositAmount = item.depositAmount else { return notAvailable }

        return wonText(depositAmount)
    }

    var totalCost: String {
        guard let totalCostAmount = item.totalCostAmount else { return notAvailable }
        return wonText(totalCostAmount)
    }

    var pricePerMonth: String {
        guard let pricePerMonthAmount = item.pricePerMonthAmount else { return "" }
        return String(
            format: localized("chat.applicationCard.value.monthlyPrice"),
            wonText(pricePerMonthAmount)
        )
    }

    func localized(_ key: String) -> String {
        language.localizedString(forKey: key)
    }

    private var locale: Locale {
        language.locale
    }

    private var notAvailable: String {
        localized("chat.applicationCard.value.notAvailable")
    }

    private func displayText(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, trimmedValue != "N/A" else { return notAvailable }
        return trimmedValue
    }

    private func wonText(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        return "₩ \(formatter.string(from: NSNumber(value: value)) ?? "\(value)")"
    }
}
