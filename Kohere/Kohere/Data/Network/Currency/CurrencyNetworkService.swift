//
//  CurrencyNetworkService.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Alamofire
import Foundation

final class CurrencyNetworkService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private var cachedKRWToUSDRateResponseDTO: FrankfurterRateResponseDTO?

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func fetchKRWToUSDRate() async throws -> FrankfurterRateResponseDTO {
        if let cachedKRWToUSDRateResponseDTO {
            return cachedKRWToUSDRateResponseDTO
        }

        let responseDTO = try await request(
            CurrencyRouter.krwToUSDExchangeRate,
            as: FrankfurterRateResponseDTO.self
        )
        cachedKRWToUSDRateResponseDTO = responseDTO

        return responseDTO
    }

    private func request<Response: Decodable>(
        _ urlRequest: URLRequestConvertible,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        do {
            let request = try urlRequest.asURLRequest()
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                throw DataError.httpStatus(code: httpResponse.statusCode, message: nil)
            }

            guard !data.isEmpty else {
                throw DataError.emptyResponse
            }

            return try decoder.decode(responseType, from: data)
        } catch let dataError as DataError {
            throw dataError
        } catch {
            throw DataError.underlying(message: error.localizedDescription)
        }
    }
}
