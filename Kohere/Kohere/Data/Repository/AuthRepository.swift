//
//  AuthRepository.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import ComposableArchitecture

final class AuthRepository: AuthInterface {
    private let networkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment
    
    init(
        networkService: NetworkService = NetworkService(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.networkService = networkService
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
    
    func logout(accessToken: String, refreshToken: String) async throws {
        let environment = try environmentProvider()
        let requestDTO = LogoutRequestDTO(refreshToken: refreshToken)
        
        try await networkService.requestVoid(
            AuthRouter.logout(
                requestDTO,
                accessToken: accessToken,
                environment: environment
            )
        )
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

private extension SocialLoginResponseDTO {
    func toEntity() -> Auth {
        Auth(
            onboardingRequired: onboardingRequired,
            status: AuthStatus(rawValue: status) ?? .unknown,
            tokenType: tokenType,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
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
