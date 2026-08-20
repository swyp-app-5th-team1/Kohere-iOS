//
//  DropdownMenuOption.swift
//  Kohere
//
//  Created by soomin on 6/21/26.
//

import Foundation

struct DropdownMenuOption: Identifiable, Equatable {
    let option: String
    var id: String { option }

    nonisolated init(option: String) {
        self.option = option
    }

    nonisolated static func == (lhs: DropdownMenuOption, rhs: DropdownMenuOption) -> Bool {
        lhs.option == rhs.option
    }
}

extension DropdownMenuOption {
    func localizedTitle(locale: Locale) -> String {
        if let month = Self.monthNumberByOption[option] {
            return Self.localizedMonth(month, locale: locale)
        }

        if let countryCode = nationalityCountryCode {
            return Locale(identifier: locale.identifier).localizedString(forRegionCode: countryCode) ?? option
        }

        if let gender {
            return AppLanguage(locale: locale).localized(gender.localizedResource)
        }

        if let visaType {
            return AppLanguage(locale: locale).localized(visaType.localizedResource)
        }

        return option
    }
}

extension DropdownMenuOption {
    static let months: [DropdownMenuOption] = [
        DropdownMenuOption(option: "JAN"),
        DropdownMenuOption(option: "FEB"),
        DropdownMenuOption(option: "MAR"),
        DropdownMenuOption(option: "APR"),
        DropdownMenuOption(option: "MAY"),
        DropdownMenuOption(option: "JUN"),
        DropdownMenuOption(option: "JUL"),
        DropdownMenuOption(option: "AUG"),
        DropdownMenuOption(option: "SEP"),
        DropdownMenuOption(option: "OCT"),
        DropdownMenuOption(option: "NOV"),
        DropdownMenuOption(option: "DEC")
    ]

    static let days = (1...31).map {
        DropdownMenuOption(option: String($0))
    }

    static let years = (1950...2026).reversed().map {
        DropdownMenuOption(option: String($0))
    }

    static let visas = VisaType.allCases.map(DropdownMenuOption.init)

    static let nationalities = ["Korea, Republic of", "United States", "Japan", "China", "Vietnam", "Canada", "United Kingdom", "France", "Spain", "Italy", "Turkey", "Hungary"].map {
        DropdownMenuOption(option: $0)
    }

    static let genders = Gender.allCases.map(DropdownMenuOption.init)
}

extension DropdownMenuOption {
    static func formattedBirthDate(
        year selectedYear: DropdownMenuOption?,
        month selectedMonth: DropdownMenuOption?,
        day selectedDay: DropdownMenuOption?
    ) -> String? {
        guard let selectedYear,
              let selectedMonth,
              let selectedDay,
              let month = monthNumberByOption[selectedMonth.option],
              let year = Int(selectedYear.option),
              let day = Int(selectedDay.option),
              isValidBirthDate(year: year, month: month, day: day) else {
            return nil
        }

        return "\(selectedYear.option)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
    }

    nonisolated init(_ gender: Gender) {
        self.init(option: gender.displayTitle)
    }

    nonisolated init(_ visaType: VisaType) {
        self.init(option: visaType.displayTitle)
    }

    nonisolated var gender: Gender? {
        Gender.allCases.first { $0.displayTitle == option }
    }

    nonisolated var visaType: VisaType? {
        VisaType.allCases.first { $0.displayTitle == option }
    }

    var nationalityCountryCode: String? {
        Self.countryCodeByNationalityOption[option]
    }

    static func nationalityOption(countryCode: String?) -> DropdownMenuOption? {
        guard let countryCode else { return nil }

        return nationalities.first { $0.nationalityCountryCode == countryCode }
    }

    private static let countryCodeByNationalityOption: [String: String] = [
        "Korea, Republic of": "KR",
        "United States": "US",
        "Japan": "JP",
        "China": "CN",
        "Vietnam": "VN",
        "Canada": "CA",
        "United Kingdom": "GB",
        "France": "FR",
        "Spain": "ES",
        "Italy": "IT",
        "Turkey": "TR",
        "Hungary": "HU"
    ]

    private static let monthNumberByOption: [String: Int] = [
        "JAN": 1,
        "FEB": 2,
        "MAR": 3,
        "APR": 4,
        "MAY": 5,
        "JUN": 6,
        "JUL": 7,
        "AUG": 8,
        "SEP": 9,
        "OCT": 10,
        "NOV": 11,
        "DEC": 12
    ]

    private static func localizedMonth(_ month: Int, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale

        guard formatter.shortStandaloneMonthSymbols.indices.contains(month - 1) else {
            return months[month - 1].option
        }

        return formatter.shortStandaloneMonthSymbols[month - 1]
    }

    private static func isValidBirthDate(year: Int, month: Int, day: Int) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard let date = calendar.date(from: components) else {
            return false
        }

        let resolvedComponents = calendar.dateComponents([.year, .month, .day], from: date)
        return resolvedComponents.year == year
            && resolvedComponents.month == month
            && resolvedComponents.day == day
    }
}

private extension Gender {
    nonisolated var displayTitle: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        }
    }

    var localizedResource: LocalizedStringResource {
        switch self {
        case .male:
            .accountGenderMale
        case .female:
            .accountGenderFemale
        }
    }
}

private extension VisaType {
    nonisolated var displayTitle: String {
        switch self {
        case .shortTermVisit:
            "Short Term Visit(C-1~4, B)"
        case .studentsTrainees:
            "Students & Trainees(D-2, D-3, D-4)"
        case .nonProfessionalWorkers:
            "Non-Professional Workers(E-8, E-9, E-10, H-2)"
        case .workingHolidayWorkAndVisit:
            "Working Holiday/Work and Visit(H-1, H-2)"
        case .overseasKoreans:
            "Overseas Koreans(F-4)"
        case .familyMarriageMigrants:
            "Family/Marriage Migrants(F-1, F-2, F-3, F-6)"
        case .permanentResidents:
            "Permanent Residents(F-5)"
        case .professionals:
            "Professionals(C-4, D-1, D-7~10, E-1~7)"
        case .diplomaticOfficialAndOthers:
            "Diplomatic/Official & Others(A-1, A-2, G-1)"
        case .etc:
            "etc"
        }
    }

    var localizedResource: LocalizedStringResource {
        switch self {
        case .shortTermVisit:
            .onboardingOptionVisaShortTermVisit
        case .studentsTrainees:
            .onboardingOptionVisaStudentsTrainees
        case .nonProfessionalWorkers:
            .onboardingOptionVisaNonProfessionalWorkers
        case .workingHolidayWorkAndVisit:
            .onboardingOptionVisaWorkingHolidayWorkAndVisit
        case .overseasKoreans:
            .onboardingOptionVisaOverseasKoreans
        case .familyMarriageMigrants:
            .onboardingOptionVisaFamilyMarriageMigrants
        case .permanentResidents:
            .onboardingOptionVisaPermanentResidents
        case .professionals:
            .onboardingOptionVisaProfessionals
        case .diplomaticOfficialAndOthers:
            .onboardingOptionVisaDiplomaticOfficialAndOthers
        case .etc:
            .onboardingOptionVisaEtc
        }
    }
}
