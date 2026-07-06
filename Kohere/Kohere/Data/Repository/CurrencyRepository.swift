//
//  CurrencyRepository.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

final class CurrencyRepository: CurrencyInterface {
    private let networkService: CurrencyNetworkService

    init(networkService: CurrencyNetworkService = CurrencyNetworkService()) {
        self.networkService = networkService
    }

    func fetchKRWToUSDExchangeRate() async throws -> KRWToUSDExchangeRate {
        let responseDTO = try await networkService.fetchKRWToUSDRate()
        return responseDTO.toEntity()
    }
}

extension CurrencyClient: DependencyKey {
    static let liveValue: CurrencyClient = {
        let repository: any CurrencyInterface = CurrencyRepository()
        return CurrencyClient(repository: repository)
    }()
}

private extension FrankfurterRateResponseDTO {
    func toEntity() -> KRWToUSDExchangeRate {
        KRWToUSDExchangeRate(usdPerKRW: rate)
    }
}
