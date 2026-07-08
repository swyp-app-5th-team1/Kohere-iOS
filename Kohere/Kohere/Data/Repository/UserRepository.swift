//
//  UserRepository.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

final class UserRepository: UserInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = .authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchCurrentUser() async throws -> UserProfile {
        let environment = try environmentProvider()
        let responseDTO: UserProfileResponseDTO = try await authenticatedNetworkService.request(
            UserRouter.me(environment)
        )

        return responseDTO.toEntity()
    }

    func deleteCurrentUser() async throws {
        let environment = try environmentProvider()

        try await authenticatedNetworkService.requestVoid(
            UserRouter.deleteMe(environment)
        )

        #if DEBUG
        print("[UserRepository] delete current user succeeded.")
        #endif
    }
}

extension UserClient: DependencyKey {
    static let liveValue: UserClient = {
        let repository: any UserInterface = UserRepository()
        return UserClient(repository: repository)
    }()
}

private extension UserProfileResponseDTO {
    func toEntity() -> UserProfile {
        UserProfile(
            id: id,
            userType: UserType(rawValue: userType) ?? .unknown,
            firstName: firstName,
            lastName: lastName,
            name: name,
            nickname: nickname ?? "",
            gender: gender,
            birthDate: birthDate,
            country: country,
            countryName: countryName,
            countryFlag: countryFlag.flatMap(URL.init(string:)),
            occupation: occupation,
            email: email,
            visaType: visaType,
            phoneNumber: phoneNumber,
            businessRegistrationNumber: businessRegistrationNumber,
            status: AuthStatus(rawValue: status) ?? .unknown,
            termsOfServiceAgreed: termsOfServiceAgreed,
            privacyPolicyAgreed: privacyPolicyAgreed,
            marketingAgreed: marketingAgreed,
            createdAt: createdAt
        )
    }
}
