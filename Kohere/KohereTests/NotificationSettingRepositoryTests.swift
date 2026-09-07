import Alamofire
import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class NotificationSettingRepositoryTests: XCTestCase {
    func testBothMethodsReturnEntityWithServerValue() async throws {
        let repository = makeRepository()
        for isUpdate in [false, true] {
            for enabled in [false, true] {
                let body = Data("""
                {"success":true,"data":{"chatPushEnabled":\(enabled)},"error":null}
                """.utf8)
                NotificationSettingMockURLProtocol.handler.setValue { _ in (200, body) }
                let preferences = try await perform(repository, isUpdate: isUpdate)
                XCTAssertEqual(preferences, UserNotificationPreferences(chatPushEnabled: enabled))
            }
        }
    }

    func testBothMethodsMapDocumentedServerErrors() async throws {
        let cases: [(String, Int, NotificationSettingError)] = [
            ("INVALID_INPUT", 400, .invalidInput),
            ("MALFORMED_REQUEST", 400, .malformedRequest),
            ("UNAUTHENTICATED", 401, .unauthenticated),
            ("TOKEN_EXPIRED", 401, .tokenExpired),
            ("AUTH_ONBOARDING_REQUIRED", 403, .onboardingRequired),
            ("FUTURE_CODE", 500, .requestFailed(.serverError(code: "FUTURE_CODE", message: "test")))
        ]
        let repository = makeRepository()

        for isUpdate in [false, true] {
            for (code, status, expected) in cases {
                let body = errorBody(code: code)
                NotificationSettingMockURLProtocol.handler.setValue { request in
                    XCTAssertEqual(request.httpMethod, isUpdate ? "PATCH" : "GET")
                    XCTAssertEqual(request.url?.path, "/api/v1/users/me/notification-preferences")
                    return (status, body)
                }
                do {
                    _ = try await perform(repository, isUpdate: isUpdate)
                    XCTFail("Expected notification settings failure")
                } catch {
                    XCTAssertEqual(error as? NotificationSettingError, expected)
                }
            }
        }
    }

    func testBothMethodsPreserveCommonFailureDetailsAndCancellation() async {
        let failures: [Error] = [
            DataError.transport(message: "Offline"),
            DataError.decodingFailed,
            DataError.missingBaseURL,
            CancellationError()
        ]
        for isUpdate in [false, true] {
            for failure in failures {
                let repository = UserRepository(
                    authenticatedNetworkService: NetworkService(),
                    environmentProvider: { throw failure }
                )
                do {
                    _ = try await perform(repository, isUpdate: isUpdate)
                    XCTFail("Expected failure")
                } catch {
                    if failure is CancellationError {
                        XCTAssertTrue(error is CancellationError)
                    } else {
                        XCTAssertEqual(error as? NotificationSettingError, .requestFailed(failure as! DataError))
                    }
                }
            }
        }
    }

    func testAlreadyMappedErrorSurvivesFeatureBoundary() {
        XCTAssertEqual(NotificationSettingError.from(NotificationSettingError.onboardingRequired),
                       .onboardingRequired)
        XCTAssertEqual(NotificationSettingError.from(NotificationSettingError.requestFailed(.decodingFailed)),
                       .requestFailed(.decodingFailed))
    }

    func testBothMethodsAllowCommonAuthRefreshAndRetryBeforeMapping() async throws {
        for isUpdate in [false, true] {
            let auth = Auth(onboardingRequired: false, status: .active, tokenType: "Bearer",
                            accessToken: "old-test-token", refreshToken: "test-refresh-token", expiresIn: 3600)
            let encodedAuth = try JSONEncoder().encode(auth)
            let storedAuth = LockIsolated(encodedAuth)
            let refreshCount = LockIsolated(0)
            let headers = LockIsolated<[String]>([])
            let keychain = KeychainClient(
                save: { _, data in storedAuth.setValue(data) },
                read: { _ in storedAuth.value },
                delete: { _ in XCTFail("Successful refresh must preserve authentication") }
            )
            let interceptor = AuthInterceptor(
                keychainClient: keychain,
                refreshManager: RefreshTokenManager(),
                reissueToken: { _ in
                    refreshCount.withValue { $0 += 1 }
                    return AuthToken(tokenType: "Bearer", accessToken: "new-test-token",
                                     refreshToken: "new-test-refresh-token", expiresIn: 3600)
                }
            )
            let expiredBody = errorBody(code: "TOKEN_EXPIRED")
            NotificationSettingMockURLProtocol.handler.setValue { request in
                let header = request.value(forHTTPHeaderField: "Authorization") ?? ""
                headers.withValue { $0.append(header) }
                if header == "Bearer old-test-token" { return (401, expiredBody) }
                return (200, Data(#"{"success":true,"data":{"chatPushEnabled":false},"error":null}"#.utf8))
            }
            let repository = makeRepository(interceptor: interceptor)
            let result = try await perform(repository, isUpdate: isUpdate)

            XCTAssertFalse(result.chatPushEnabled)
            XCTAssertEqual(refreshCount.value, 1)
            XCTAssertEqual(headers.value, ["Bearer old-test-token", "Bearer new-test-token"])
        }
    }

    func testOtherUserRequestsStillThrowDataError() async {
        let body = errorBody(code: "AUTH_ONBOARDING_REQUIRED")
        NotificationSettingMockURLProtocol.handler.setValue { _ in (403, body) }
        do {
            _ = try await makeRepository().fetchCurrentUser()
            XCTFail("Expected user profile failure")
        } catch {
            XCTAssertEqual(error as? DataError,
                           .serverError(code: "AUTH_ONBOARDING_REQUIRED", message: "test"))
        }
    }

    private func perform(_ repository: UserRepository, isUpdate: Bool) async throws -> UserNotificationPreferences {
        if isUpdate { return try await repository.updateNotificationPreferences(chatPushEnabled: false) }
        return try await repository.fetchNotificationPreferences()
    }

    private func makeRepository(interceptor: (any RequestInterceptor)? = nil) -> UserRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NotificationSettingMockURLProtocol.self]
        return UserRepository(
            authenticatedNetworkService: NetworkService(
                session: Session(configuration: configuration, interceptor: interceptor)
            ),
            environmentProvider: { APIEnvironment(baseURL: URL(string: "https://notification-settings.test")!) }
        )
    }

    private func errorBody(code: String) -> Data {
        Data("""
        {"success":false,"data":null,"error":{"code":"\(code)","message":"test","errors":[]}}
        """.utf8)
    }
}

/// 이 테스트가 주입한 Session에서만 HTTP 응답을 대체한다.
private final class NotificationSettingMockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (Int, Data)
    static let handler = LockIsolated<Handler>({ _ in throw URLError(.unknown) })

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (status, data) = try Self.handler.value(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
