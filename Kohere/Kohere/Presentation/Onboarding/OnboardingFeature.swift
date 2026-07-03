//
//  OnboardingFeature.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import ComposableArchitecture
import Foundation

enum OnboardingUserType: Equatable {
    case tenant
    case landlord
}

enum Step: Equatable, Comparable {
    case nameAndBirth
    case details
    case emailVerification
    case landlordNameAndBirth
    case landlordPhoneVerification
    
    static func < (lhs: Step, rhs: Step) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
    
    var progressIndex: Int {
        switch self {
        case .nameAndBirth, .landlordNameAndBirth:
            return 1
        case .details, .landlordPhoneVerification:
            return 2
        case .emailVerification:
            return 3
        }
    }
    
    private var sortOrder: Int {
        switch self {
        case .nameAndBirth:
            return 1
        case .details:
            return 2
        case .emailVerification:
            return 3
        case .landlordNameAndBirth:
            return 4
        case .landlordPhoneVerification:
            return 5
        }
    }
}

@Reducer
struct OnboardingFeature {
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var userType: OnboardingUserType
        var currentStep: Step
        
        var lastName: String = ""
        var firstName: String = ""
        var selectedMonth: DropdownMenuOption?
        var selectedDay: DropdownMenuOption?
        var selectedYear: DropdownMenuOption?
        
        var selectedVisa: DropdownMenuOption?
        var selectedOccupation: DropdownMenuOption?
        var selectedNationality: DropdownMenuOption?
        var selectedGender: DropdownMenuOption?
        
        var email: String = ""
        var verificationCode: String = ""
        var isEmailVerified: Bool = false
        var isCodeSent: Bool = false
        var lastVerificationCodeSentEmail: String?
        var emailMessage: String?
        var emailVerificationCodeErrorMessage: String?
        
        var landlordName: String = ""
        var phoneNumber: String = ""
        var phoneVerificationCode: String = ""
        var isPhoneVerified: Bool = false
        var isPhoneCodeSent: Bool = false
        var lastVerificationCodeSentPhoneNumber: String?
        var phoneMessage: String?
        var phoneVerificationCodeErrorMessage: String?
        
        init(userType: OnboardingUserType = .tenant) {
            self.userType = userType
            self.currentStep = userType == .tenant ? .nameAndBirth : .landlordNameAndBirth
        }
        
        var totalStepCount: Int {
            switch userType {
            case .tenant:
                return 3
            case .landlord:
                return 2
            }
        }
        
        var primaryButtonTitle: String {
            switch userType {
            case .tenant:
                return currentStep == .emailVerification ? "Get Started" : "Next"
            case .landlord:
                return currentStep == .landlordPhoneVerification ? "시작하기" : "다음"
            }
        }
        
        var isNextButtonEnabled: Bool {
            switch currentStep {
            case .nameAndBirth:
                return !lastName.isEmpty && !firstName.isEmpty && selectedMonth != nil && selectedDay != nil && selectedYear != nil
            case .details:
                return selectedVisa != nil && selectedOccupation != nil && selectedNationality != nil && selectedGender != nil
            case .emailVerification:
                return isEmailVerified
            case .landlordNameAndBirth:
                return !landlordName.isEmpty && selectedMonth != nil && selectedDay != nil && selectedYear != nil
            case .landlordPhoneVerification:
                return isPhoneVerified
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
            return domain.contains(".") && domain.last != "."
        }
        
        var canConfirmEmailVerificationCode: Bool {
            isCodeSent && !verificationCode.isEmpty
        }
        
        var hasPhoneNumberFormatError: Bool {
            guard !phoneNumber.isEmpty else { return false }
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            return phoneNumber.rangeOfCharacter(from: allowedCharacters.inverted) != nil
        }
        
        var canSendPhoneVerificationCode: Bool {
            let digitCount = phoneNumber.filter(\.isNumber).count
            return !phoneNumber.isEmpty && !hasPhoneNumberFormatError && digitCount >= 10
        }
        
        var canConfirmPhoneVerificationCode: Bool {
            isPhoneCodeSent && phoneVerificationCode.count == 6
        }
    }
    
    // MARK: - Action
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case nextButtonTapped
        case backButtonTapped
        case sendVerificationCodeTapped
        case confirmVerificationCodeTapped
        case sendPhoneVerificationCodeTapped
        case confirmPhoneVerificationCodeTapped
        case verificationSuccess
        case onboardingCompleted
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(let action):
                if action.keyPath == \.phoneNumber {
                    state.phoneNumber = state.phoneNumber.filter { $0.isNumber }
                    state.resetPhoneVerificationIfNeeded()
                }
                
                if action.keyPath == \.email {
                    state.resetEmailVerificationIfNeeded()
                }
                if action.keyPath == \.verificationCode {
                    state.emailVerificationCodeErrorMessage = nil
                }
                if action.keyPath == \.phoneVerificationCode {
                    state.phoneVerificationCode = state.phoneVerificationCode.filter { $0.isNumber }
                    state.phoneVerificationCodeErrorMessage = nil
                }
                return .none
                
            case .nextButtonTapped:
                if state.currentStep == .nameAndBirth {
                    state.currentStep = .details
                } else if state.currentStep == .details {
                    state.currentStep = .emailVerification
                } else if state.currentStep == .emailVerification {
                    // TODO: 홈화면 전환
                } else if state.currentStep == .landlordNameAndBirth {
                    state.currentStep = .landlordPhoneVerification
                }
                return .none
                
            case .backButtonTapped:
                if state.currentStep == .details {
                    state.currentStep = .nameAndBirth
                } else if state.currentStep == .emailVerification {
                    state.currentStep = .details
                } else if state.currentStep == .landlordPhoneVerification {
                    state.currentStep = .landlordNameAndBirth
                }
                return .none
                
            case .sendVerificationCodeTapped:
                let trimmedEmail = state.email.trimmingCharacters(in: .whitespacesAndNewlines)
                state.email = trimmedEmail
                guard state.canSendEmailVerificationCode else {
                    return .none
                }
                state.isCodeSent = true
                state.lastVerificationCodeSentEmail = trimmedEmail
                state.verificationCode = ""
                state.isEmailVerified = false
                state.emailMessage = "Verification code sent to your email."
                state.emailVerificationCodeErrorMessage = nil
                return .none
                
            case .confirmVerificationCodeTapped:
                guard state.canConfirmEmailVerificationCode else {
                    return .none
                }
                // TODO: 서버 검증 성공 시에만 진입 버튼 활성화
                if state.verificationCode == "000000" {
                    state.isEmailVerified = true
                    state.emailMessage = nil
                    state.emailVerificationCodeErrorMessage = nil
                } else if state.verificationCode == "999999" {
                    state.emailVerificationCodeErrorMessage = "This code is expired - Tap Resend"
                } else {
                    state.emailVerificationCodeErrorMessage = "This code is incorrect - Please try again"
                }
                return .none
                
            case .sendPhoneVerificationCodeTapped:
                let trimmedPhoneNumber = state.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                state.phoneNumber = trimmedPhoneNumber
                guard state.canSendPhoneVerificationCode else {
                    return .none
                }
                state.isPhoneCodeSent = true
                state.lastVerificationCodeSentPhoneNumber = trimmedPhoneNumber
                state.phoneVerificationCode = ""
                state.isPhoneVerified = false
                state.phoneMessage = "Verification code sent to your message."
                state.phoneVerificationCodeErrorMessage = nil
                return .none
                
            case .confirmPhoneVerificationCodeTapped:
                guard state.canConfirmPhoneVerificationCode else {
                    return .none
                }
                // TODO: 서버 검증 성공 시에만 진입 버튼 활성화
                if state.phoneVerificationCode == "000000" {
                    state.isPhoneVerified = true
                    state.phoneMessage = nil
                    state.phoneVerificationCodeErrorMessage = nil
                } else if state.phoneVerificationCode == "999999" {
                    state.phoneVerificationCodeErrorMessage = "This code is expired - Tap Resend"
                } else {
                    state.phoneVerificationCodeErrorMessage = "This code is incorrect - Please try again"
                }
                return .none
                
            case .verificationSuccess:
                state.isEmailVerified = true
                return .none
                
            case .onboardingCompleted:
                return .none
            }
        }
    }
}

private extension OnboardingFeature.State {
    mutating func resetEmailVerificationIfNeeded() {
        guard email != lastVerificationCodeSentEmail else {
            return
        }
        isCodeSent = false
        isEmailVerified = false
        lastVerificationCodeSentEmail = nil
        verificationCode = ""
        emailMessage = nil
        emailVerificationCodeErrorMessage = nil
    }
    
    mutating func resetPhoneVerificationIfNeeded() {
        guard phoneNumber != lastVerificationCodeSentPhoneNumber else {
            return
        }
        isPhoneCodeSent = false
        isPhoneVerified = false
        lastVerificationCodeSentPhoneNumber = nil
        phoneVerificationCode = ""
        phoneMessage = nil
        phoneVerificationCodeErrorMessage = nil
    }
}
