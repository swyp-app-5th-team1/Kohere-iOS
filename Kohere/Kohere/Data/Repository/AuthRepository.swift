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
        authenticatedNetworkService: NetworkService = .authenticated(),
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
        defer {
            try? keychainClient.delete(for: .auth)
        }
        
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

private enum AuthRepositoryError: Error {
    case missingAuth
    case missingRefreshToken
}
