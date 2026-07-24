//
//  LandlordOnboardingSupport.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

import Foundation

extension LandlordOnboardingFeature.State {
    var totalStepCount: Int {
        2
    }

    var primaryButtonTitle: String {
        currentStep == .phoneVerification ? "시작하기" : "다음"
    }

    var isNextButtonEnabled: Bool {
        switch currentStep {
        case .nameAndBirth:
            return birthDate != nil
        case .phoneVerification:
            return isPhoneVerified && !isOnboardingSubmitting
        }
    }

    var canSendPhoneVerificationCode: Bool {
        let digitCount = phoneNumber.filter(\.isNumber).count
        return !phoneNumber.isEmpty && digitCount >= 10 && !isPhoneVerificationCodeRequesting
    }

    var canConfirmPhoneVerificationCode: Bool {
        isPhoneCodeSent && phoneVerificationCode.count == 6 && !isPhoneVerificationRequesting
    }

    var normalizedPhoneNumber: String {
        String(phoneNumber.filter(\.isNumber))
    }

    var onboardingProfile: LandlordOnboardingProfile? {
        guard let birthDate else {
            return nil
        }

        let phoneNumber = normalizedPhoneNumber

        guard !phoneNumber.isEmpty else {
            return nil
        }

        return LandlordOnboardingProfile(
            phoneNumber: phoneNumber,
            birthDate: birthDate
        )
    }

    mutating func resetPhoneVerificationIfNeeded() {
        guard phoneNumber != lastVerificationCodeSentPhoneNumber else {
            return
        }
        isPhoneCodeSent = false
        isPhoneVerified = false
        isPhoneVerificationCodeRequesting = false
        isPhoneVerificationRequesting = false
        lastVerificationCodeSentPhoneNumber = nil
        phoneVerificationCode = ""
        phoneMessage = nil
        phoneVerificationCodeErrorMessage = nil
    }

    private var birthDate: String? {
        DropdownMenuOption.formattedBirthDate(
            year: selectedYear,
            month: selectedMonth,
            day: selectedDay
        )
    }
}
