//
//  OnboardingFeature.swift
//  Kohere
//
//  Created by soomin on 6/21/26.
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

        init(
            userType: OnboardingUserType = .tenant,
            appLanguage: AppLanguage = .systemDefault,
            socialName: String? = nil
        ) {
            self.userType = userType

            switch userType {
            case .tenant:
                self.tenant = TenantOnboardingFeature.State(appLanguage: appLanguage, name: socialName ?? "")
                self.landlord = nil
            case .landlord:
                self.tenant = nil
                self.landlord = LandlordOnboardingFeature.State(name: socialName ?? "")
            }
        }
    }

    // MARK: - Action

    enum Delegate: Equatable {
        case completed(Auth)
        case popupRequested(AppPopup)
    }

    enum Action: Equatable {
        case tenant(TenantOnboardingFeature.Action)
        case landlord(LandlordOnboardingFeature.Action)
        case delegate(Delegate)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case let .tenant(.onboardingResponse(.success(auth))):
                return .send(.delegate(.completed(auth)))

            case let .landlord(.onboardingResponse(.success(auth))):
                return .send(.delegate(.completed(auth)))

            case let .tenant(.popupRequested(popup)),
                 let .landlord(.popupRequested(popup)):
                return .send(.delegate(.popupRequested(popup)))

            case .tenant, .landlord, .delegate:
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
