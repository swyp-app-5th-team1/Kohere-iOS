//
//  LandlordOnboardingFeature.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LandlordOnboardingFeature {
    @Dependency(\.sendPhoneVerificationCodeUseCase)
    var sendPhoneVerificationCodeUseCase
    @Dependency(\.verifyPhoneUseCase)
    var verifyPhoneUseCase
    @Dependency(\.completeLandlordOnboardingUseCase)
    var completeLandlordOnboardingUseCase

    enum Step: Equatable, Comparable {
        case nameAndBirth
        case phoneVerification

        static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.progressIndex < rhs.progressIndex
        }

        var progressIndex: Int {
            switch self {
            case .nameAndBirth:
                return 1
            case .phoneVerification:
                return 2
            }
        }
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .nameAndBirth

        var landlordName: String = ""
        var selectedMonth: DropdownMenuOption?
        var selectedDay: DropdownMenuOption?
        var selectedYear: DropdownMenuOption?

        var phoneNumber: String = ""
        var phoneVerificationCode: String = ""
        var isPhoneVerified: Bool = false
        var isPhoneCodeSent: Bool = false
        var isPhoneVerificationCodeRequesting: Bool = false
        var isPhoneVerificationRequesting: Bool = false
        var lastVerificationCodeSentPhoneNumber: String?
        var phoneMessage: String?
        var phoneVerificationCodeErrorMessage: String?

        var isOnboardingSubmitting: Bool = false
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case nextButtonTapped
        case backButtonTapped
        case sendPhoneVerificationCodeTapped
        case sendPhoneVerificationCodeResponse(String, Result<PhoneVerificationCode, DataError>)
        case confirmPhoneVerificationCodeTapped
        case confirmPhoneVerificationCodeResponse(Result<PhoneVerification, DataError>)
        case onboardingCompleted
        case onboardingResponse(Result<Auth, DataError>)
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
                if action.keyPath == \.phoneVerificationCode {
                    state.phoneVerificationCode = state.phoneVerificationCode.filter { $0.isNumber }
                    state.phoneVerificationCodeErrorMessage = nil
                }
                return .none

            case .nextButtonTapped:
                if state.currentStep == .nameAndBirth {
                    state.currentStep = .phoneVerification
                }
                return .none

            case .backButtonTapped:
                if state.currentStep == .phoneVerification {
                    state.currentStep = .nameAndBirth
                }
                return .none

            case .sendPhoneVerificationCodeTapped:
                let trimmedPhoneNumber = state.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                state.phoneNumber = trimmedPhoneNumber
                guard state.canSendPhoneVerificationCode else {
                    return .none
                }
                state.isPhoneVerificationCodeRequesting = true
                state.phoneMessage = nil
                state.phoneVerificationCodeErrorMessage = nil
                let phoneNumber = state.normalizedPhoneNumber

                return .run { send in
                    do {
                        let response = try await sendPhoneVerificationCodeUseCase.execute(phoneNumber)
                        await send(.sendPhoneVerificationCodeResponse(trimmedPhoneNumber, .success(response)))
                    } catch {
                        await send(.sendPhoneVerificationCodeResponse(trimmedPhoneNumber, .failure(DataError.from(error))))
                    }
                }

            case let .sendPhoneVerificationCodeResponse(requestedPhoneNumber, .success):
                guard state.phoneNumber == requestedPhoneNumber else {
                    return .none
                }
                state.isPhoneVerificationCodeRequesting = false
                state.isPhoneCodeSent = true
                state.lastVerificationCodeSentPhoneNumber = requestedPhoneNumber
                state.phoneVerificationCode = ""
                state.isPhoneVerified = false
                state.phoneMessage = "휴대폰으로 인증 코드를 보냈어요."
                state.phoneVerificationCodeErrorMessage = nil
                return .none

            case let .sendPhoneVerificationCodeResponse(requestedPhoneNumber, .failure):
                guard state.phoneNumber == requestedPhoneNumber else {
                    return .none
                }
                state.isPhoneVerificationCodeRequesting = false
                return .none

            case .confirmPhoneVerificationCodeTapped:
                let trimmedCode = state.phoneVerificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
                state.phoneVerificationCode = trimmedCode
                guard state.canConfirmPhoneVerificationCode else {
                    return .none
                }
                state.isPhoneVerificationRequesting = true
                state.phoneVerificationCodeErrorMessage = nil
                let phoneNumber = state.normalizedPhoneNumber

                return .run { send in
                    do {
                        let response = try await verifyPhoneUseCase.execute(phoneNumber, trimmedCode)
                        await send(.confirmPhoneVerificationCodeResponse(.success(response)))
                    } catch {
                        await send(.confirmPhoneVerificationCodeResponse(.failure(DataError.from(error))))
                    }
                }

            case let .confirmPhoneVerificationCodeResponse(.success(response)):
                state.isPhoneVerificationRequesting = false
                state.isPhoneVerified = response.verified
                state.phoneMessage = nil
                state.phoneVerificationCodeErrorMessage = response.verified
                    ? nil
                    : "인증 코드가 올바르지 않아요. 다시 시도해주세요."
                return .none

            case let .confirmPhoneVerificationCodeResponse(.failure(error)):
                state.isPhoneVerificationRequesting = false
                if case let .serverError(code, _) = error, code == "AUTH_PHONE_VERIFICATION_FAILED" {
                    state.phoneVerificationCodeErrorMessage = "인증 코드가 올바르지 않거나 만료됐어요. 다시 시도해주세요."
                }
                return .none

            case .onboardingCompleted:
                guard let profile = state.onboardingProfile else {
                    return .none
                }
                state.isOnboardingSubmitting = true

                return .run { send in
                    do {
                        let auth = try await completeLandlordOnboardingUseCase.execute(profile)
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
