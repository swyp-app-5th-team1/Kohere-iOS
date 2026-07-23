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
        currentStep == .emailVerification
            ? appLanguage.localized("common.start")
            : appLanguage.localized("common.next")
    }

    var isNextButtonEnabled: Bool {
        switch currentStep {
        case .nameAndBirth:
            return !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && birthDate != nil
        case .details:
            return selectedVisa != nil && selectedNationality != nil && selectedGender != nil
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
              let country = selectedNationality?.nationalityCountryCode,
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
        DropdownMenuOption.formattedBirthDate(
            year: selectedYear,
            month: selectedMonth,
            day: selectedDay
        )
    }
}
