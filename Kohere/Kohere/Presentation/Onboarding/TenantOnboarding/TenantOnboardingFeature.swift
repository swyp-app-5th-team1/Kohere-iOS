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
    @Dependency(\.completeOnboardingUseCase)
    var completeOnboardingUseCase

    enum Step: Equatable, Comparable {
        case nameAndBirth
        case details

        static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.progressIndex < rhs.progressIndex
        }

        var progressIndex: Int {
            switch self {
            case .nameAndBirth:
                return 1
            case .details:
                return 2
            }
        }
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var appLanguage: AppLanguage = .systemDefault
        var currentStep: Step = .nameAndBirth

        var name: String = ""
        var selectedMonth: DropdownMenuOption?
        var selectedDay: DropdownMenuOption?
        var selectedYear: DropdownMenuOption?

        var selectedVisa: VisaType?
        var selectedNationality: DropdownMenuOption?
        var selectedGender: Gender?

        var isOnboardingSubmitting: Bool = false
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case nextButtonTapped
        case backButtonTapped
        case onboardingCompleted
        case onboardingResponse(Result<Auth, DataError>)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .nextButtonTapped:
                switch state.currentStep {
                case .nameAndBirth:
                    state.currentStep = .details
                case .details:
                    break
                }
                return .none

            case .backButtonTapped:
                switch state.currentStep {
                case .details:
                    state.currentStep = .nameAndBirth
                case .nameAndBirth:
                    break
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
