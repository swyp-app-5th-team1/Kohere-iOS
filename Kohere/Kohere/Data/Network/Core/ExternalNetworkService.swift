//
//  ExternalNetworkService.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

nonisolated final class ExternalNetworkService: @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let errorParser: (@Sendable (Data) -> DataError?)?

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        errorParser: (@Sendable (Data) -> DataError?)? = nil
    ) {
        self.session = session
        self.decoder = decoder
        self.errorParser = errorParser
    }

    func request<Response: Decodable>(
        _ urlRequest: URLRequestConvertible,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        do {
            let request = try urlRequest.asURLRequest()
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                throw errorParser?(data)
                    ?? DataError.httpStatus(code: httpResponse.statusCode, message: nil)
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
