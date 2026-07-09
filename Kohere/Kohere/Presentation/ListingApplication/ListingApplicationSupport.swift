//
//  ListingApplicationSupport.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import Foundation

enum ListingApplicationStep: Equatable {
    case dateSelection
    case review
}

enum ListingApplicationPrivacySection: String, CaseIterable, Equatable, Hashable, Identifiable {
    case collection
    case thirdParty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collection: "개인정보 수집 및 이용 안내"
        case .thirdParty: "개인정보 제 3자 제공 동의"
        }
    }

    var url: URL {
        switch self {
        case .collection:
            URL(string: "https://jewel-humor-b3e.notion.site/39777dadb98580298266c7fa779a5502?source=copy_link")!
        case .thirdParty:
            URL(string: "https://jewel-humor-b3e.notion.site/3-39777dadb98580f1ac63ec8ceef52fa4?source=copy_link")!
        }
    }
}

enum ListingApplicationDelegate: Equatable {
    case listingDetailRequested(listingID: String)
    case chatTabRequested
    case privacyDocumentRequested(ListingApplicationPrivacySection)
}

extension ListingApplicationFeature.State {
    nonisolated static func expiryDate(startDate: Date, months: Int) -> Date {
        let startOfDay = calendar.startOfDay(for: startDate)
        return calendar.date(
            byAdding: .month,
            value: months,
            to: startOfDay
        ) ?? startOfDay
    }

    nonisolated static func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    nonisolated static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    nonisolated static var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }

    nonisolated static var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd (E)"
        return formatter
    }

    nonisolated static var koreanDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 M월 d일(E)"
        return formatter
    }
}

extension ListingApplicationFeature {
    nonisolated static func shiftMonth(_ month: Date, by value: Int) -> Date {
        ListingApplicationFeature.State.calendar.date(
            byAdding: .month,
            value: value,
            to: month
        ) ?? month
    }

    nonisolated static func monthDate(year: Int, month: Int) -> Date {
        ListingApplicationFeature.State.calendar.date(
            from: DateComponents(year: year, month: month, day: 1)
        ) ?? Date()
    }

    nonisolated static func clampedDisplayedMonth(
        _ month: Date,
        minimumDate: Date
    ) -> Date {
        let minimumMonth = ListingApplicationFeature.State.monthStart(for: minimumDate)
        let maximumMonth = ListingApplicationFeature.State.monthStart(
            for: maximumMoveInDate(minimumDate: minimumDate)
        )

        if month < minimumMonth { return minimumMonth }
        if month > maximumMonth { return maximumMonth }
        return month
    }

    nonisolated static func isSelectableDate(
        _ date: Date,
        minimumDate: Date
    ) -> Bool {
        let maximumDate = maximumMoveInDate(minimumDate: minimumDate)
        return date >= minimumDate && date <= maximumDate
    }

    nonisolated static func maximumMoveInDate(minimumDate: Date) -> Date {
        let minimumYear = ListingApplicationFeature.State.calendar.component(
            .year,
            from: minimumDate
        )

        return ListingApplicationFeature.State.calendar.date(
            from: DateComponents(year: minimumYear + 4, month: 12, day: 31)
        ) ?? minimumDate
    }

    nonisolated static func applicantSummary(from profile: UserProfile) -> String {
        let name = firstNonEmpty([
            profile.name,
            fullName(firstName: profile.firstName, lastName: profile.lastName),
            profile.nickname
        ]) ?? "이름 정보 없음"
        let gender = readableGender(profile.gender)
        let country = firstNonEmpty([
            profile.countryName,
            profile.country.flatMap(countryTitle),
            profile.country
        ])

        return [name, gender, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    nonisolated private static func fullName(firstName: String?, lastName: String?) -> String? {
        let parts = [firstName, lastName]
            .compactMap { normalizedText($0) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " ")
    }

    nonisolated private static func readableGender(_ rawValue: String?) -> String? {
        guard let value = normalizedText(rawValue), !value.isEmpty else { return nil }

        switch value.uppercased() {
        case Gender.male.rawValue:
            return "Male"
        case Gender.female.rawValue:
            return "Female"
        default:
            return value
        }
    }

    nonisolated private static func countryTitle(countryCode: String) -> String? {
        countryTitleByCode[countryCode.uppercased()]
    }

    nonisolated private static func firstNonEmpty(_ values: [String?]) -> String? {
        values.compactMap { normalizedText($0) }.first { !$0.isEmpty }
    }

    nonisolated private static func normalizedText(_ text: String?) -> String? {
        text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static let countryTitleByCode: [String: String] = [
        "KR": "Korea, Republic of",
        "US": "United States",
        "JP": "Japan",
        "CN": "China",
        "VN": "Vietnam",
        "CA": "Canada",
        "GB": "United Kingdom",
        "FR": "France",
        "ES": "Spain",
        "IT": "Italy",
        "TR": "Turkey",
        "HU": "Hungary"
    ]
}
