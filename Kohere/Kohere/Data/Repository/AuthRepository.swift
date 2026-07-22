//
//  AuthRepository.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

final class AuthRepository: AuthInterface {
    private let networkService: NetworkService
    private let authenticatedNetworkService: NetworkService
    private let keychainClient: KeychainClient
    private let environmentProvider: () throws -> APIEnvironment
    
    init(
        networkService: NetworkService = .plain(),
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        keychainClient: KeychainClient = .liveValue,
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.networkService = networkService
        self.authenticatedNetworkService = authenticatedNetworkService
        self.keychainClient = keychainClient
        self.environmentProvider = environmentProvider
    }
    
    func socialLogin(credential: SocialLoginCredential) async throws -> Auth {
        let environment = try environmentProvider()
        let requestDTO = SocialLoginRequestDTO(credential)
        let responseDTO: SocialLoginResponseDTO = try await networkService.request(
            AuthRouter.socialLogin(requestDTO, environment)
        )
        
        return responseDTO.toEntity()
    }
    
    func reissue(refreshToken: String) async throws -> AuthToken {
        let environment = try environmentProvider()
        let requestDTO = ReissueTokenRequestDTO(refreshToken: refreshToken)
        let responseDTO: TokenResponseDTO = try await networkService.request(
            AuthRouter.reissue(requestDTO, environment)
        )
        
        return responseDTO.toEntity()
    }
    
    func logout() async throws {
        var remoteLogoutFailed = false

        do {
            let auth = try loadStoredAuth()
            guard let refreshToken = auth.refreshToken else {
                throw AuthRepositoryError.missingRefreshToken
            }

            let environment = try environmentProvider()
            let requestDTO = LogoutRequestDTO(refreshToken: refreshToken)

            try await authenticatedNetworkService.requestVoid(
                AuthRouter.logout(
                    requestDTO,
                    environment
                )
            )
        } catch {
            remoteLogoutFailed = true
        }

        do {
            try keychainClient.delete(for: .auth)
        } catch {
            throw LogoutError.localAuthCleanupFailed
        }

        if remoteLogoutFailed {
            throw LogoutError.remoteRequestFailed
        }
    }

    func sendPhoneVerificationCode(phoneNumber: String) async throws -> PhoneVerificationCode {
        let environment = try environmentProvider()
        let requestDTO = PhoneVerificationCodeRequestDTO(phoneNumber: phoneNumber)
        let responseDTO: PhoneVerificationCodeResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.sendPhoneVerificationCode(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func verifyPhone(phoneNumber: String, code: String) async throws -> PhoneVerification {
        let environment = try environmentProvider()
        let requestDTO = PhoneVerificationRequestDTO(
            phoneNumber: phoneNumber,
            code: code
        )
        let responseDTO: PhoneVerificationResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.verifyPhone(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func sendEmailVerificationCode(email: String) async throws -> EmailVerificationCode {
        let environment = try environmentProvider()
        let requestDTO = EmailVerificationCodeRequestDTO(email: email)
        let responseDTO: EmailVerificationCodeResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.sendEmailVerificationCode(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func verifyEmail(email: String, code: String) async throws -> EmailVerification {
        let environment = try environmentProvider()
        let requestDTO = EmailVerificationRequestDTO(
            email: email,
            code: code
        )
        let responseDTO: EmailVerificationResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.verifyEmail(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func agreeTerms(
        termsOfServiceAgreed: Bool,
        privacyPolicyAgreed: Bool,
        marketingAgreed: Bool
    ) async throws -> TermsAgreement {
        let environment = try environmentProvider()
        let requestDTO = TermsAgreementRequestDTO(
            termsOfServiceAgreed: termsOfServiceAgreed,
            privacyPolicyAgreed: privacyPolicyAgreed,
            marketingAgreed: marketingAgreed
        )
        let responseDTO: TermsAgreementResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.agreeTerms(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func completeOnboarding(profile: AuthOnboardingProfile) async throws -> Auth {
        let environment = try environmentProvider()
        let requestDTO = AuthOnboardingRequestDTO(
            firstName: profile.firstName,
            lastName: profile.lastName,
            gender: profile.gender.rawValue,
            birthDate: profile.birthDate,
            country: profile.country,
            occupation: profile.occupation.rawValue,
            email: profile.email,
            visaType: profile.visaType.rawValue
        )
        let responseDTO: AuthOnboardingResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.completeOnboarding(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }

    func completeLandlordOnboarding(profile: LandlordOnboardingProfile) async throws -> Auth {
        let environment = try environmentProvider()
        let requestDTO = LandlordOnboardingRequestDTO(
            name: profile.name,
            phoneNumber: profile.phoneNumber,
            birthDate: profile.birthDate
        )
        let responseDTO: AuthOnboardingResponseDTO = try await authenticatedNetworkService.request(
            AuthRouter.completeLandlordOnboarding(
                requestDTO,
                environment
            )
        )

        return responseDTO.toEntity()
    }
    
    private func loadStoredAuth() throws -> Auth {
        guard let auth = try keychainClient.load(for: .auth) else {
            throw AuthRepositoryError.missingAuth
        }
        
        return auth
    }
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        let repository: any AuthInterface = AuthRepository()
        return AuthClient(repository: repository)
    }()
}

private extension SocialLoginRequestDTO {
    init(_ credential: SocialLoginCredential) {
        switch credential {
        case let .google(idToken):
            self = .google(idToken: idToken)

        case let .apple(authorizationCode):
            self = .apple(authorizationCode: authorizationCode)
        }
    }
}

// MARK: - Mapper

private extension SocialLoginResponseDTO {
    func toEntity() -> Auth {
        return Auth(
            onboardingRequired: onboardingRequired,
            status: AuthStatus(rawValue: status) ?? .unknown,
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            expiresAt: Auth.expirationDate(expiresIn: expiresIn)
        )
    }
}

private extension TokenResponseDTO {
    func toEntity() -> AuthToken {
        AuthToken(
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

private extension PhoneVerificationCodeResponseDTO {
    func toEntity() -> PhoneVerificationCode {
        PhoneVerificationCode(
            message: message,
            phoneNumber: phoneNumber,
            expiresIn: expiresIn
        )
    }
}

private extension PhoneVerificationResponseDTO {
    func toEntity() -> PhoneVerification {
        PhoneVerification(
            phoneNumber: phoneNumber,
            verified: verified
        )
    }
}

private extension EmailVerificationCodeResponseDTO {
    func toEntity() -> EmailVerificationCode {
        EmailVerificationCode(
            message: message,
            email: email,
            expiresIn: expiresIn
        )
    }
}

private extension EmailVerificationResponseDTO {
    func toEntity() -> EmailVerification {
        EmailVerification(
            email: email,
            verified: verified
        )
    }
}

private extension TermsAgreementResponseDTO {
    func toEntity() -> TermsAgreement {
        TermsAgreement(
            status: status,
            termsOfServiceAgreed: termsOfServiceAgreed,
            privacyPolicyAgreed: privacyPolicyAgreed,
            marketingAgreed: marketingAgreed,
            agreedAt: agreedAt
        )
    }
}

private extension AuthOnboardingResponseDTO {
    func toEntity() -> Auth {
        Auth(
            onboardingRequired: false,
            status: AuthStatus(rawValue: user.status) ?? .unknown,
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            expiresAt: Auth.expirationDate(expiresIn: expiresIn)
        )
    }
}

private enum AuthRepositoryError: Error {
    case missingAuth
    case missingRefreshToken
}
