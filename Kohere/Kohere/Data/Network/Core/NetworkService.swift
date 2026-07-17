//
//  NetworkService.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import Alamofire
import Foundation

final class NetworkService {
    private let session: Session
    private let decoder: JSONDecoder
    
    init(
        session: Session = .default,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }
    
    func request<Response: Decodable>(
        _ urlRequest: URLRequestConvertible,
        as responseType: Response.Type = Response.self,
        debugRawJSONLabel: String? = nil
    ) async throws -> Response {
        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
        
        let statusCode = response.response?.statusCode
        let data = response.data ?? Data()

        if let debugRawJSONLabel {
            debugLogRawJSON(
                data: data,
                request: response.request,
                statusCode: statusCode,
                label: debugRawJSONLabel
            )
        }
        
        if let statusCode, !(200..<300).contains(statusCode) {
            throw parseServerError(from: data) ?? DataError.httpStatus(code: statusCode, message: nil)
        }

        if let error = response.error {
            throw mapAFError(error)
        }
        
        guard !data.isEmpty else {
            throw DataError.emptyResponse
        }
        
        do {
            if let serverError = parseServerError(from: data) {
                throw serverError
            }
            
            let baseResponse = try decoder.decode(BaseResponseDTO<Response>.self, from: data)
            
            guard baseResponse.success, let responseData = baseResponse.data else {
                throw DataError.emptyResponse
            }
            
            return responseData
        } catch let dataError as DataError {
            throw dataError
        } catch {
            throw DataError.decodingFailed
        }
    }

    private func debugLogRawJSON(
        data: Data,
        request: URLRequest?,
        statusCode: Int?,
        label: String
    ) {
        #if DEBUG
        let method = request?.httpMethod ?? "REQUEST"
        let url = request?.url?.absoluteString ?? "unknown URL"
        let statusText = statusCode.map(String.init) ?? "unknown"
        let bodyText = Self.prettyJSONString(from: data)

        print(
            """

            [RawJSON][\(label)]
            \(method) \(url)
            status: \(statusText)
            body:
            \(bodyText)
            [RawJSON][end]

            """
        )
        #endif
    }

    private static func prettyJSONString(from data: Data) -> String {
        guard !data.isEmpty else { return "<empty body>" }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8) ?? "<non-utf8 body: \(data.count) bytes>"
        }

        return prettyString
    }
    
    func requestVoid(_ urlRequest: URLRequestConvertible) async throws {
        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
        
        let statusCode = response.response?.statusCode
        let data = response.data ?? Data()
        
        if let statusCode, !(200..<300).contains(statusCode) {
            throw parseServerError(from: data) ?? DataError.httpStatus(code: statusCode, message: nil)
        }

        if let error = response.error {
            throw mapAFError(error)
        }
        
        if !data.isEmpty, let error = parseServerError(from: data) {
            throw error
        }
    }
    
    private func parseServerError(from data: Data) -> DataError? {
        guard !data.isEmpty else { return nil }
        
        do {
            let baseResponse = try decoder.decode(BaseResponseDTO<EmptyResponseDTO>.self, from: data)
            guard let error = baseResponse.error else { return nil }
            return .serverError(code: error.code, message: error.message)
        } catch {
            return nil
        }
    }
    
    private func mapAFError(_ error: AFError) -> DataError {
        if error.isSessionTaskError {
            return .transport(message: error.localizedDescription)
        }

        return .underlying(message: error.localizedDescription)
    }
}

extension NetworkService {
    static func plain() -> NetworkService {
        NetworkService(session: .default)
    }
}

enum LiveNetworkServiceFactory {
    private static let authenticatedNetworkService = NetworkService(
        session: Session(
            interceptor: AuthInterceptor(refreshManager: RefreshTokenManager())
        )
    )

    static func authenticated() -> NetworkService {
        authenticatedNetworkService
    }
}

private struct EmptyResponseDTO: Decodable {}
