//
//  AuthInterface.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

protocol AuthInterface {
    func socialLogin(credential: SocialLoginCredential) async throws -> Auth
    func reissue(refreshToken: String) async throws -> AuthToken
    func logout() async throws
    func sendPhoneVerificationCode(phoneNumber: String) async throws -> PhoneVerificationCode
    func verifyPhone(phoneNumber: String, code: String) async throws -> PhoneVerification
    func sendEmailVerificationCode(email: String) async throws -> EmailVerificationCode
    func verifyEmail(email: String, code: String) async throws -> EmailVerification
    func agreeTerms(termsOfServiceAgreed: Bool, privacyPolicyAgreed: Bool, marketingAgreed: Bool) async throws -> TermsAgreement
    func completeOnboarding(profile: AuthOnboardingProfile) async throws -> Auth
    func completeLandlordOnboarding(profile: LandlordOnboardingProfile) async throws -> Auth
}

struct AuthClient: Sendable {
    var socialLogin: @Sendable (_ credential: SocialLoginCredential) async throws -> Auth
    var reissue: @Sendable (_ refreshToken: String) async throws -> AuthToken
    var logout: @Sendable () async throws -> Void
    var sendPhoneVerificationCode: @Sendable (_ phoneNumber: String) async throws -> PhoneVerificationCode
    var verifyPhone: @Sendable (_ phoneNumber: String, _ code: String) async throws -> PhoneVerification
    var sendEmailVerificationCode: @Sendable (_ email: String) async throws -> EmailVerificationCode
    var verifyEmail: @Sendable (_ email: String, _ code: String) async throws -> EmailVerification
    var agreeTerms: @Sendable (_ termsOfServiceAgreed: Bool, _ privacyPolicyAgreed: Bool, _ marketingAgreed: Bool) async throws -> TermsAgreement
    var completeOnboarding: @Sendable (_ profile: AuthOnboardingProfile) async throws -> Auth
    var completeLandlordOnboarding: @Sendable (_ profile: LandlordOnboardingProfile) async throws -> Auth
}

extension AuthClient {
    init(repository: any AuthInterface) {
        self.init(
            socialLogin: { credential in
                try await repository.socialLogin(credential: credential)
            },
            reissue: { refreshToken in
                try await repository.reissue(refreshToken: refreshToken)
            },
            logout: {
                try await repository.logout()
            },
            sendPhoneVerificationCode: { phoneNumber in
                try await repository.sendPhoneVerificationCode(phoneNumber: phoneNumber)
            },
            verifyPhone: { phoneNumber, code in
                try await repository.verifyPhone(phoneNumber: phoneNumber, code: code)
            },
            sendEmailVerificationCode: { email in
                try await repository.sendEmailVerificationCode(email: email)
            },
            verifyEmail: { email, code in
                try await repository.verifyEmail(email: email, code: code)
            },
            agreeTerms: { termsOfServiceAgreed, privacyPolicyAgreed, marketingAgreed in
                try await repository.agreeTerms(
                    termsOfServiceAgreed: termsOfServiceAgreed,
                    privacyPolicyAgreed: privacyPolicyAgreed,
                    marketingAgreed: marketingAgreed
                )
            },
            completeOnboarding: { profile in
                try await repository.completeOnboarding(profile: profile)
            },
            completeLandlordOnboarding: { profile in
                try await repository.completeLandlordOnboarding(profile: profile)
            }
        )
    }
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
