//
//  DataError+.swift
//  Kohere
//
//  Created by mandoo on 7/5/26.
//

import Foundation

extension DataError {
    static func from(_ error: Error) -> DataError {
        if let dataError = error as? DataError { return dataError }
        return .underlying(message: error.localizedDescription)
    }
}

enum OnboardingErrorContext {
    case completeProfile
    case sendPhoneVerificationCode
    case verifyPhone
    case saveAuthentication

    var localizationKey: String {
        switch self {
        case .completeProfile:
            "onboarding.error.completeProfile"
        case .sendPhoneVerificationCode:
            "onboarding.error.sendPhoneVerificationCode"
        case .verifyPhone:
            "onboarding.error.verifyPhone"
        case .saveAuthentication:
            "onboarding.error.saveAuthentication"
        }
    }
}

enum OnboardingErrorPopup {
    static func make(context: OnboardingErrorContext, language: AppLanguage) -> AppPopup {
        .notice(
            AppPopup.Notice(message: language.localized(context.localizationKey), confirmTitle: language.localized("common.confirm"))
        )
    }
}
