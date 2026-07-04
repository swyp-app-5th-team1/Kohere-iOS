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
            return !landlordName.isEmpty && selectedMonth != nil && selectedDay != nil && selectedYear != nil
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
        let trimmedName = landlordName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneNumber = normalizedPhoneNumber

        guard !trimmedName.isEmpty, !phoneNumber.isEmpty else {
            return nil
        }

        return LandlordOnboardingProfile(
            name: trimmedName,
            phoneNumber: phoneNumber
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
}
