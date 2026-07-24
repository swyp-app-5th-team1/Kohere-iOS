//
//  TenantOnboardingSupport.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

import Foundation

extension TenantOnboardingFeature.State {
    var totalStepCount: Int {
        2
    }

    var primaryButtonTitle: String {
        currentStep == .details
            ? appLanguage.localized("common.start")
            : appLanguage.localized("common.next")
    }

    var isNextButtonEnabled: Bool {
        switch currentStep {
        case .nameAndBirth:
            return birthDate != nil
        case .details:
            return selectedVisa != nil && selectedNationality != nil && selectedGender != nil
        }
    }

    var onboardingProfile: AuthOnboardingProfile? {
        guard let birthDate,
              let gender = selectedGender,
              let country = selectedNationality?.nationalityCountryCode,
              let visaType = selectedVisa else {
            return nil
        }

        return AuthOnboardingProfile(
            gender: gender,
            birthDate: birthDate,
            country: country,
            visaType: visaType,
            lang: appLanguage.rawValue
        )
    }

    private var birthDate: String? {
        DropdownMenuOption.formattedBirthDate(
            year: selectedYear,
            month: selectedMonth,
            day: selectedDay
        )
    }
}
