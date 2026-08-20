//
//  CompleteOnboardingUseCase.swift
//  Kohere
//
//  Created by soomin on 7/3/26.
//

import ComposableArchitecture

struct CompleteOnboardingUseCase {
    var execute: (_ profile: AuthOnboardingProfile) async throws -> Auth
}

extension CompleteOnboardingUseCase: DependencyKey {
    static let liveValue: CompleteOnboardingUseCase = {
        @Dependency(\.authClient)
        var authClient

        return CompleteOnboardingUseCase { profile in
            try await authClient.completeOnboarding(profile)
        }
    }()
}

extension DependencyValues {
    var completeOnboardingUseCase: CompleteOnboardingUseCase {
        get { self[CompleteOnboardingUseCase.self] }
        set { self[CompleteOnboardingUseCase.self] = newValue }
    }
}
