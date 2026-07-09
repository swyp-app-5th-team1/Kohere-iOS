//
//  OnboardingFeature.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import ComposableArchitecture
import Foundation

enum OnboardingUserType: String, Equatable {
    case tenant
    case landlord
}

@Reducer
struct OnboardingFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var userType: OnboardingUserType
        var tenant: TenantOnboardingFeature.State?
        var landlord: LandlordOnboardingFeature.State?

        init(userType: OnboardingUserType = .tenant) {
            self.userType = userType

            switch userType {
            case .tenant:
                self.tenant = TenantOnboardingFeature.State()
                self.landlord = nil
            case .landlord:
                self.tenant = nil
                self.landlord = LandlordOnboardingFeature.State()
            }
        }
    }

    // MARK: - Action

    enum Action: Equatable {
        case tenant(TenantOnboardingFeature.Action)
        case landlord(LandlordOnboardingFeature.Action)
        case onboardingResponse(Result<Auth, DataError>)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case let .tenant(.onboardingResponse(result)):
                return .send(.onboardingResponse(result))

            case let .landlord(.onboardingResponse(result)):
                return .send(.onboardingResponse(result))

            case .tenant, .landlord, .onboardingResponse:
                return .none
            }
        }
        .ifLet(\.tenant, action: \.tenant) {
            TenantOnboardingFeature()
        }
        .ifLet(\.landlord, action: \.landlord) {
            LandlordOnboardingFeature()
        }
    }
}
