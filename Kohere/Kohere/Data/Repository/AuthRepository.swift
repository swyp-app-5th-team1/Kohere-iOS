//
//  AuthRepository.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

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

    func socialLogin(provider: SocialLoginProvider, idToken: String) async throws -> Auth {
        let environment = try environmentProvider()
        let requestDTO = SocialLoginRequestDTO(
            provider: provider.toDTO(),
            idToken: idToken
        )
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

private extension SocialLoginProvider {
    func toDTO() -> SocialLoginProviderDTO {
        switch self {
        case .google:
            .google
        }
    }
}
