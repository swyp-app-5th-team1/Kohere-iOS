//
//  TenantOnboardingSupport.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

import Foundation

extension TenantOnboardingFeature.State {
    var totalStepCount: Int {
        3
    }

    var primaryButtonTitle: String {
        currentStep == .emailVerification ? "Get Started" : "Next"
    }

    var isNextButtonEnabled: Bool {
        switch currentStep {
        case .nameAndBirth:
            return !lastName.isEmpty && !firstName.isEmpty && selectedMonth != nil && selectedDay != nil && selectedYear != nil
        case .details:
            return selectedVisa != nil && selectedOccupation != nil && selectedNationality != nil && selectedGender != nil
        case .emailVerification:
            return isEmailVerified && !isOnboardingSubmitting
        }
    }

    var hasEmailFormatError: Bool {
        guard !email.isEmpty else { return false }
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._%+-@")
        return email.rangeOfCharacter(from: allowedCharacters.inverted) != nil
    }

    var canSendEmailVerificationCode: Bool {
        guard !email.isEmpty,
              !hasEmailFormatError,
              let atIndex = email.firstIndex(of: "@") else {
            return false
        }
        let domain = email[email.index(after: atIndex)...]
        return domain.contains(".") && domain.last != "." && !isEmailVerificationCodeRequesting
    }

    var canConfirmEmailVerificationCode: Bool {
        isCodeSent && !verificationCode.isEmpty && !isEmailVerificationRequesting
    }

    var onboardingProfile: AuthOnboardingProfile? {
        guard let birthDate,
              let gender = selectedGender,
              let country = selectedNationality?.authOnboardingCountryCode,
              let occupation = selectedOccupation,
              let visaType = selectedVisa else {
            return nil
        }

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty, !trimmedEmail.isEmpty else {
            return nil
        }

        return AuthOnboardingProfile(
            firstName: trimmedFirstName,
            lastName: trimmedLastName,
            gender: gender,
            birthDate: birthDate,
            country: country,
            occupation: occupation,
            email: trimmedEmail,
            visaType: visaType
        )
    }

    mutating func resetEmailVerificationIfNeeded() {
        guard email != lastVerificationCodeSentEmail else {
            return
        }
        isCodeSent = false
        isEmailVerified = false
        isEmailVerificationCodeRequesting = false
        isEmailVerificationRequesting = false
        lastVerificationCodeSentEmail = nil
        verificationCode = ""
        emailMessage = nil
        emailVerificationCodeErrorMessage = nil
    }

    private var birthDate: String? {
        guard let selectedYear,
              let selectedMonth,
              let selectedDay,
              let month = selectedMonth.authOnboardingMonthNumber,
              let year = Int(selectedYear.option),
              let day = Int(selectedDay.option),
              Self.isValidBirthDate(year: year, month: month, day: day) else {
            return nil
        }

        return "\(selectedYear.option)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
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

extension TenantOnboardingFeature {
    static func toDataError(_ error: Error) -> DataError {
        if let dataError = error as? DataError {
            return dataError
        }

        return .underlying(message: error.localizedDescription)
    }
}

private extension DropdownMenuOption {
    var authOnboardingMonthNumber: Int? {
        Self.monthNumberByOption[option]
    }

    var authOnboardingCountryCode: String? {
        Self.countryCodeByOption[option]
    }

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

    private static let countryCodeByOption: [String: String] = [
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
}
