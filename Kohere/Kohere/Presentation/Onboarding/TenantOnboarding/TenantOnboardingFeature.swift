//
//  TenantOnboardingFeature.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TenantOnboardingFeature {
    @Dependency(\.sendEmailVerificationCodeUseCase)
    var sendEmailVerificationCodeUseCase
    @Dependency(\.verifyEmailUseCase)
    var verifyEmailUseCase
    @Dependency(\.completeOnboardingUseCase)
    var completeOnboardingUseCase

    enum Step: Equatable, Comparable {
        case nameAndBirth
        case details
        case emailVerification

        static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.progressIndex < rhs.progressIndex
        }

        var progressIndex: Int {
            switch self {
            case .nameAndBirth:
                return 1
            case .details:
                return 2
            case .emailVerification:
                return 3
            }
        }
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .nameAndBirth

        var lastName: String = ""
        var firstName: String = ""
        var selectedMonth: DropdownMenuOption?
        var selectedDay: DropdownMenuOption?
        var selectedYear: DropdownMenuOption?

        var selectedVisa: VisaType?
        var selectedOccupation: Occupation?
        var selectedNationality: DropdownMenuOption?
        var selectedGender: Gender?

        var email: String = ""
        var verificationCode: String = ""
        var isEmailVerified: Bool = false
        var isCodeSent: Bool = false
        var isEmailVerificationCodeRequesting: Bool = false
        var isEmailVerificationRequesting: Bool = false
        var lastVerificationCodeSentEmail: String?
        var emailMessage: String?
        var emailVerificationCodeErrorMessage: String?

        var isOnboardingSubmitting: Bool = false
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case nextButtonTapped
        case backButtonTapped
        case sendVerificationCodeTapped
        case sendVerificationCodeResponse(String, Result<EmailVerificationCode, DataError>)
        case confirmVerificationCodeTapped
        case confirmVerificationCodeResponse(Result<EmailVerification, DataError>)
        case onboardingCompleted
        case onboardingResponse(Result<Auth, DataError>)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(let action):
                if action.keyPath == \.email {
                    state.resetEmailVerificationIfNeeded()
                }
                if action.keyPath == \.verificationCode {
                    state.emailVerificationCodeErrorMessage = nil
                }
                return .none

            case .nextButtonTapped:
                switch state.currentStep {
                case .nameAndBirth:
                    state.currentStep = .details
                case .details:
                    state.currentStep = .emailVerification
                case .emailVerification:
                    break
                }
                return .none

            case .backButtonTapped:
                switch state.currentStep {
                case .details:
                    state.currentStep = .nameAndBirth
                case .emailVerification:
                    state.currentStep = .details
                case .nameAndBirth:
                    break
                }
                return .none

            case .sendVerificationCodeTapped:
                let trimmedEmail = state.email.trimmingCharacters(in: .whitespacesAndNewlines)
                state.email = trimmedEmail
                guard state.canSendEmailVerificationCode else {
                    return .none
                }
                state.isEmailVerificationCodeRequesting = true
                state.emailMessage = nil
                state.isEmailVerified = false
                state.emailVerificationCodeErrorMessage = nil

                return .run { send in
                    do {
                        let response = try await sendEmailVerificationCodeUseCase.execute(trimmedEmail)
                        await send(.sendVerificationCodeResponse(trimmedEmail, .success(response)))
                    } catch {
                        await send(.sendVerificationCodeResponse(trimmedEmail, .failure(Self.toDataError(error))))
                    }
                }

            case let .sendVerificationCodeResponse(requestedEmail, .success(response)):
                guard state.email == requestedEmail else {
                    return .none
                }
                state.isEmailVerificationCodeRequesting = false
                state.isCodeSent = true
                state.lastVerificationCodeSentEmail = requestedEmail
                state.verificationCode = ""
                state.isEmailVerified = false
                state.emailMessage = response.message ?? "Verification code sent to your email."
                state.emailVerificationCodeErrorMessage = nil
                return .none

            case let .sendVerificationCodeResponse(requestedEmail, .failure):
                guard state.email == requestedEmail else {
                    return .none
                }
                state.isEmailVerificationCodeRequesting = false
                return .none

            case .confirmVerificationCodeTapped:
                let trimmedCode = state.verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
                state.verificationCode = trimmedCode
                guard state.canConfirmEmailVerificationCode else {
                    return .none
                }
                state.isEmailVerificationRequesting = true
                state.emailVerificationCodeErrorMessage = nil
                let email = state.email

                return .run { send in
                    do {
                        let response = try await verifyEmailUseCase.execute(email, trimmedCode)
                        await send(.confirmVerificationCodeResponse(.success(response)))
                    } catch {
                        await send(.confirmVerificationCodeResponse(.failure(Self.toDataError(error))))
                    }
                }

            case let .confirmVerificationCodeResponse(.success(response)):
                state.isEmailVerificationRequesting = false
                state.isEmailVerified = response.verified
                state.emailMessage = nil
                state.emailVerificationCodeErrorMessage = response.verified ? nil : "This code is incorrect - Please try again"
                return .none

            case let .confirmVerificationCodeResponse(.failure(error)):
                state.isEmailVerificationRequesting = false
                if case let .serverError(code, _) = error, code == "AUTH_EMAIL_VERIFICATION_FAILED" {
                    state.emailVerificationCodeErrorMessage = "This code is incorrect or expired - Please try again"
                }
                return .none

            case .onboardingCompleted:
                guard let profile = state.onboardingProfile else {
                    return .none
                }
                state.isOnboardingSubmitting = true

                return .run { send in
                    do {
                        let auth = try await completeOnboardingUseCase.execute(profile)
                        await send(.onboardingResponse(.success(auth)))
                    } catch {
                        await send(.onboardingResponse(.failure(Self.toDataError(error))))
                    }
                }

            case .onboardingResponse(.success):
                state.isOnboardingSubmitting = false
                return .none

            case .onboardingResponse(.failure):
                state.isOnboardingSubmitting = false
                return .none
            }
        }
    }
}
