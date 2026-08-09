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

    func title(language: AppLanguage) -> String {
        switch self {
        case .collection:
            language.localized(.listingApplicationPrivacyCollectionTitle)
        case .thirdParty:
            language.localized(.listingApplicationPrivacyThirdPartyTitle)
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
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    nonisolated var displayLocale: Locale {
        appLanguage == .korean
            ? Locale(identifier: "ko_KR")
            : Locale(identifier: "en_US")
    }

    nonisolated var monthFormatter: DateFormatter {
        Self.dateFormatter(
            language: appLanguage,
            koreanFormat: "yyyy년 M월",
            englishFormat: "MMMM yyyy"
        )
    }

    nonisolated var compactDateFormatter: DateFormatter {
        Self.dateFormatter(
            language: appLanguage,
            koreanFormat: "yyyy.MM.dd (E)",
            englishFormat: "MMM d, yyyy (EEE)"
        )
    }

    nonisolated var reviewDateFormatter: DateFormatter {
        Self.dateFormatter(
            language: appLanguage,
            koreanFormat: "yyyy년 M월 d일(E)",
            englishFormat: "MMM d, yyyy (EEE)"
        )
    }

    nonisolated private static func dateFormatter(
        language: AppLanguage,
        koreanFormat: String,
        englishFormat: String
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = language == .korean
            ? Locale(identifier: "ko_KR")
            : Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = language == .korean
            ? koreanFormat
            : englishFormat
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

    static func applicantSummary(
        from profile: UserProfile,
        locale: Locale = Locale(identifier: "en_US")
    ) -> String {
        let name = firstNonEmpty([
            profile.name,
            profile.nickname
        ])
        let gender = readableGender(profile.gender, locale: locale)
        let country = firstNonEmpty([
            profile.country.flatMap { countryTitle(countryCode: $0, locale: locale) },
            profile.countryName,
            profile.country
        ])

        return [name, gender, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private static func readableGender(
        _ rawValue: String?,
        locale: Locale
    ) -> String? {
        guard let value = normalizedText(rawValue), !value.isEmpty else { return nil }

        switch value.uppercased() {
        case Gender.male.rawValue:
            return AppLanguage(locale: locale).localized(.listingApplicationApplicantGenderMale)
        case Gender.female.rawValue:
            return AppLanguage(locale: locale).localized(.listingApplicationApplicantGenderFemale)
        default:
            return value
        }
    }

    nonisolated private static func countryTitle(
        countryCode: String,
        locale: Locale
    ) -> String? {
        locale.localizedString(forRegionCode: countryCode.uppercased())
    }

    nonisolated private static func firstNonEmpty(_ values: [String?]) -> String? {
        values.compactMap { normalizedText($0) }.first { !$0.isEmpty }
    }

    nonisolated private static func normalizedText(_ text: String?) -> String? {
        text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
