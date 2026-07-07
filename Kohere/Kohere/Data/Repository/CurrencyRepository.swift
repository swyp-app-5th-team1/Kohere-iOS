//
//  CurrencyRepository.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import ComposableArchitecture

actor CurrencyRepository: CurrencyInterface {
    private let networkService: CurrencyNetworkService
    private var cachedKRWToUSDExchangeRate: KRWToUSDExchangeRate?
    private var inFlightKRWToUSDExchangeRateTask: Task<KRWToUSDExchangeRate, Error>?

    init(networkService: CurrencyNetworkService = CurrencyNetworkService()) {
        self.networkService = networkService
    }

    func fetchKRWToUSDExchangeRate() async throws -> KRWToUSDExchangeRate {
        if let cachedKRWToUSDExchangeRate {
            return cachedKRWToUSDExchangeRate
        }

        if let inFlightKRWToUSDExchangeRateTask {
            return try await inFlightKRWToUSDExchangeRateTask.value
        }

        let task = Task<KRWToUSDExchangeRate, Error> { [networkService] in
            do {
                let responseDTO: FrankfurterRateResponseDTO = try await networkService.request(
                    CurrencyRouter.krwToUSDExchangeRate
                )
                return responseDTO.toEntity()
            } catch {
                throw CurrencyError.exchangeRateUnavailable
            }
        }

        inFlightKRWToUSDExchangeRateTask = task

        do {
            let exchangeRate = try await task.value
            cachedKRWToUSDExchangeRate = exchangeRate
            inFlightKRWToUSDExchangeRateTask = nil
            return exchangeRate
        } catch {
            inFlightKRWToUSDExchangeRateTask = nil
            throw error
        }
    }
}

extension CurrencyClient: DependencyKey {
    static let liveValue: CurrencyClient = {
        let repository: any CurrencyInterface = CurrencyRepository()
        return CurrencyClient(repository: repository)
    }()
}

private extension FrankfurterRateResponseDTO {
    nonisolated func toEntity() -> KRWToUSDExchangeRate {
        KRWToUSDExchangeRate(usdPerKRW: rate)
    }
}
