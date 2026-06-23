//
//  OnboardingFeature.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import ComposableArchitecture
import Foundation

enum Step: Int, Equatable, Comparable {
    case nameAndBirth = 1
    case details = 2
    case emailVerification = 3
    
    static func < (lhs: Step, rhs: Step) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

@Reducer
struct OnboardingFeature {
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .nameAndBirth
        
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
        
        var isNextButtonEnabled: Bool {
            switch currentStep {
            case .nameAndBirth:
                return !lastName.isEmpty && !firstName.isEmpty && selectedMonth != nil && selectedDay != nil && selectedYear != nil
            case .details:
                return selectedVisa != nil && selectedOccupation != nil && selectedNationality != nil && selectedGender != nil
            case .emailVerification:
                return isEmailVerified
            }
        }
    }
    
    // MARK: - Action
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case nextButtonTapped
        case backButtonTapped
        case sendVerificationCodeTapped
        case confirmVerificationCodeTapped
        case verificationSuccess
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(let action):
                if action.keyPath == \.email {
                    state.isCodeSent = false
                    state.isEmailVerified = false
                    state.verificationCode = ""
                }
                return .none
                
            case .nextButtonTapped:
                if state.currentStep == .nameAndBirth {
                    state.currentStep = .details
                } else if state.currentStep == .details {
                    state.currentStep = .emailVerification
                } else if state.currentStep == .emailVerification {
                    // TODO: 홈화면 전환
                }
                return .none
                
            case .backButtonTapped:
                if state.currentStep == .details {
                    state.currentStep = .nameAndBirth
                } else if state.currentStep == .emailVerification {
                    state.currentStep = .details
                }
                return .none
                
            case .sendVerificationCodeTapped:
                state.isCodeSent = true
                return .none
                
            case .confirmVerificationCodeTapped:
                // TODO: - 서버와 연동
                if !state.verificationCode.isEmpty {
                    state.isEmailVerified = true
                }
                return .none
                
            case .verificationSuccess:
                state.isEmailVerified = true
                return .none
            }
        }
    }
}
