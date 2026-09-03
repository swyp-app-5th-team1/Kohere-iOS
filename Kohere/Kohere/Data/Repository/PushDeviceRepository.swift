//
//  PushDeviceRepository.swift
//  Kohere
//
//  Created by 송규섭 on 9/1/26.
//

import ComposableArchitecture
import Foundation

final class PushDeviceRepository: PushDeviceInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func registerDevice(installationId: String, fcmToken: String) async throws {
        let environment = try environmentProvider()
        let requestDTO = RegisterPushDeviceRequestDTO(fcmToken: fcmToken)

        try await authenticatedNetworkService.requestVoid(
            PushDeviceRouter.register(installationId: installationId, requestDTO, environment)
        )
    }

    func unregisterDevice(installationId: String) async throws {
        let environment = try environmentProvider()

        try await authenticatedNetworkService.requestVoid(
            PushDeviceRouter.unregister(installationId: installationId, environment)
        )
    }
}

extension PushDeviceClient: DependencyKey {
    static let liveValue: PushDeviceClient = {
        let repository: any PushDeviceInterface = PushDeviceRepository()
        return PushDeviceClient(repository: repository)
    }()
}
