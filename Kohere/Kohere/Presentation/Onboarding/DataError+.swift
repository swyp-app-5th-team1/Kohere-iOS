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

    var localizedResource: LocalizedStringResource {
        switch self {
        case .completeProfile:
            .onboardingErrorCompleteProfile
        case .sendPhoneVerificationCode:
            .onboardingErrorSendPhoneVerificationCode
        case .verifyPhone:
            .onboardingErrorVerifyPhone
        case .saveAuthentication:
            .onboardingErrorSaveAuthentication
        }
    }
}

enum OnboardingErrorPopup {
    static func make(context: OnboardingErrorContext, language: AppLanguage) -> AppPopup {
        .notice(
            AppPopup.Notice(
                message: language.localized(context.localizedResource),
                confirmTitle: language.localized(.commonConfirm)
            )
        )
    }
}
