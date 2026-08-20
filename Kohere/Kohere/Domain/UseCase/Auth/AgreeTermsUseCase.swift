//
//  AgreeTermsUseCase.swift
//  Kohere
//
//  Created by soomin on 7/3/26.
//

import ComposableArchitecture

struct AgreeTermsUseCase {
    var execute: (
        _ termsOfServiceAgreed: Bool,
        _ privacyPolicyAgreed: Bool,
        _ marketingAgreed: Bool
    ) async throws -> TermsAgreement
}

extension AgreeTermsUseCase: DependencyKey {
    static let liveValue: AgreeTermsUseCase = {
        @Dependency(\.authClient)
        var authClient

        return AgreeTermsUseCase { termsOfServiceAgreed, privacyPolicyAgreed, marketingAgreed in
            try await authClient.agreeTerms(
                termsOfServiceAgreed,
                privacyPolicyAgreed,
                marketingAgreed
            )
        }
    }()
}

extension DependencyValues {
    var agreeTermsUseCase: AgreeTermsUseCase {
        get { self[AgreeTermsUseCase.self] }
        set { self[AgreeTermsUseCase.self] = newValue }
    }
}
