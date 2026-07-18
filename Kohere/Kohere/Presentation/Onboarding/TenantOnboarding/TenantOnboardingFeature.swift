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
        var appLanguage: AppLanguage = .systemDefault
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
                Self.debugLogEmailVerification(
                    "send code requested. email=\(Self.maskedEmail(trimmedEmail))"
                )

                return .run { send in
                    do {
                        let response = try await sendEmailVerificationCodeUseCase.execute(trimmedEmail)
                        await send(.sendVerificationCodeResponse(trimmedEmail, .success(response)))
                    } catch {
                        await send(.sendVerificationCodeResponse(trimmedEmail, .failure(DataError.from(error))))
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
                state.emailMessage = state.appLanguage.localized("onboarding.verification.emailSent")
                state.emailVerificationCodeErrorMessage = nil
                Self.debugLogEmailVerification(
                    "send code succeeded. email=\(Self.maskedEmail(requestedEmail)), message=\(response.message ?? "nil")"
                )
                return .none

            case let .sendVerificationCodeResponse(requestedEmail, .failure(error)):
                guard state.email == requestedEmail else {
                    return .none
                }
                state.isEmailVerificationCodeRequesting = false
                Self.debugLogEmailVerification(
                    "send code failed. email=\(Self.maskedEmail(requestedEmail)), error=\(error.localizedDescription)"
                )
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
                        await send(.confirmVerificationCodeResponse(.failure(DataError.from(error))))
                    }
                }

            case let .confirmVerificationCodeResponse(.success(response)):
                state.isEmailVerificationRequesting = false
                state.isEmailVerified = response.verified
                state.emailMessage = nil
                state.emailVerificationCodeErrorMessage = response.verified
                    ? nil
                    : state.appLanguage.localized("onboarding.verification.codeIncorrect")
                return .none

            case let .confirmVerificationCodeResponse(.failure(error)):
                state.isEmailVerificationRequesting = false
                if case let .serverError(code, _) = error, code == "AUTH_EMAIL_VERIFICATION_FAILED" {
                    state.emailVerificationCodeErrorMessage = state.appLanguage.localized(
                        "onboarding.verification.codeIncorrectOrExpired"
                    )
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
                        await send(.onboardingResponse(.failure(DataError.from(error))))
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

private extension TenantOnboardingFeature {
    static func debugLogEmailVerification(_ message: String) {
#if DEBUG
        print("[TenantOnboarding][EmailVerification] \(message)")
#endif
    }

    static func maskedEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1)
        guard parts.count == 2 else { return "***" }

        let name = String(parts[0])
        let domain = String(parts[1])
        let prefix = name.prefix(2)
        return "\(prefix)***@\(domain)"
    }
}
