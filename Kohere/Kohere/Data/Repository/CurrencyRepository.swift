//
//  CurrencyRepository.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

final class CurrencyRepository: CurrencyInterface {
    private let networkService: CurrencyNetworkService
    private var cachedKRWToUSDExchangeRate: KRWToUSDExchangeRate?

    init(networkService: CurrencyNetworkService = CurrencyNetworkService()) {
        self.networkService = networkService
    }

    func fetchKRWToUSDExchangeRate() async throws -> KRWToUSDExchangeRate {
        if let cachedKRWToUSDExchangeRate {
            return cachedKRWToUSDExchangeRate
        }

        let responseDTO: FrankfurterRateResponseDTO = try await networkService.request(
            CurrencyRouter.krwToUSDExchangeRate
        )
        let exchangeRate = responseDTO.toEntity()
        cachedKRWToUSDExchangeRate = exchangeRate

        return exchangeRate
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
