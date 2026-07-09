//
//  DropdownMenuOption.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
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

    static let occupations = Occupation.allCases.map(DropdownMenuOption.init)

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

    nonisolated init(_ occupation: Occupation) {
        self.init(option: occupation.displayTitle)
    }

    nonisolated init(_ visaType: VisaType) {
        self.init(option: visaType.displayTitle)
    }

    nonisolated var gender: Gender? {
        Gender.allCases.first { $0.displayTitle == option }
    }

    nonisolated var occupation: Occupation? {
        Occupation.allCases.first { $0.displayTitle == option }
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
}

private extension Occupation {
    nonisolated var displayTitle: String {
        switch self {
        case .undergraduateStudent:
            "Undergraduate Student"
        case .graduateStudent:
            "Graduate Student"
        case .exchangeStudent:
            "Exchange Student"
        case .educationAcademicResearch:
            "Education/Academic Research"
        case .itSoftwareEngineering:
            "IT/Software Engineering"
        case .developer:
            "Developer"
        case .designer:
            "Designer"
        }
    }
}

private extension VisaType {
    nonisolated var displayTitle: String {
        switch self {
        case .diplomaticOfficial:
            "Diplomatic/Official(A-1,A-2)"
        case .visaExempted:
            "Visa Exempted(B)"
        case .journalismReligiousAffairs:
            "Journalism/Religious Affairs(C-1, D-5, D-6)"
        case .shortTermVisit:
            "Short Term Visit(C-2, C-3)"
        case .study:
            "Study(D-2)"
        case .trainee:
            "Trainee(D-3, D-4)"
        case .intraCompanyTransfer:
            "Intra-Company Transfer(D-7)"
        case .professional:
            "Professional(C-4, D-1, D-8, D-9, D-10, E-1, E-2, E-3, E-4, E-5, E-6, E-7)"
        case .nonProfessional:
            "Non-Professional(E-8, E-9, E-10)"
        case .workingHoliday:
            "Working Holiday(H-1)"
        case .workAndVisit:
            "Work and Visit(H-2)"
        case .familyVisitorDependent:
            "Family Visitor/Dependent Family(F-1, F-2, F-3)"
        case .overseasKorean:
            "Overseas Korean(F-4)"
        case .permanentResidence:
            "Permanent Residence(F-5)"
        case .marriageMigrant:
            "Marriage Migrant(F-6)"
        case .others:
            "Others(G-1)"
        }
    }
}
