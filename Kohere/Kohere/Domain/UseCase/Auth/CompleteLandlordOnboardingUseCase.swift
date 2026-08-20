//
//  CompleteLandlordOnboardingUseCase.swift
//  Kohere
//
//  Created by soomin on 7/3/26.
//

import ComposableArchitecture

struct CompleteLandlordOnboardingUseCase {
    var execute: (_ profile: LandlordOnboardingProfile) async throws -> Auth
}

extension CompleteLandlordOnboardingUseCase: DependencyKey {
    static let liveValue: CompleteLandlordOnboardingUseCase = {
        @Dependency(\.authClient)
        var authClient

        return CompleteLandlordOnboardingUseCase { profile in
            try await authClient.completeLandlordOnboarding(profile)
        }
    }()
}

extension DependencyValues {
    var completeLandlordOnboardingUseCase: CompleteLandlordOnboardingUseCase {
        get { self[CompleteLandlordOnboardingUseCase.self] }
        set { self[CompleteLandlordOnboardingUseCase.self] = newValue }
    }
}
