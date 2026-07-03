//
//  AuthRouter.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

import Alamofire
import Foundation

enum AuthRouter: URLRequestConvertible {
    case socialLogin(SocialLoginRequestDTO, APIEnvironment)
    case reissue(ReissueTokenRequestDTO, APIEnvironment)
    case logout(LogoutRequestDTO, accessToken: String, environment: APIEnvironment)
    case sendPhoneVerificationCode(
        PhoneVerificationCodeRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case verifyPhone(
        PhoneVerificationRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case sendEmailVerificationCode(
        EmailVerificationCodeRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case verifyEmail(
        EmailVerificationRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case agreeTerms(
        TermsAgreementRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case completeOnboarding(
        AuthOnboardingRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )
    case completeLandlordOnboarding(
        LandlordOnboardingRequestDTO,
        accessToken: String,
        environment: APIEnvironment
    )

    private var method: HTTPMethod {
        switch self {
        case .socialLogin, .reissue, .logout, .sendPhoneVerificationCode, .verifyPhone,
             .sendEmailVerificationCode, .verifyEmail, .agreeTerms, .completeOnboarding,
             .completeLandlordOnboarding:
            .post
        }
    }

    private var path: String {
        switch self {
        case .socialLogin:
            "api/v1/auth/social-login"

        case .reissue:
            "api/v1/auth/reissue"

        case .logout:
            "api/v1/auth/logout"

        case .sendPhoneVerificationCode:
            "api/v1/auth/phone/verification-code"

        case .verifyPhone:
            "api/v1/auth/phone/verify"

        case .sendEmailVerificationCode:
            "api/v1/auth/email/verification-code"

        case .verifyEmail:
            "api/v1/auth/email/verify"

        case .agreeTerms:
            "api/v1/auth/terms"

        case .completeOnboarding:
            "api/v1/auth/onboarding"

        case .completeLandlordOnboarding:
            "api/v1/auth/landlord/onboarding"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .socialLogin(_, environment),
             let .reissue(_, environment),
             let .logout(_, _, environment),
             let .sendPhoneVerificationCode(_, _, environment),
             let .verifyPhone(_, _, environment),
             let .sendEmailVerificationCode(_, _, environment),
             let .verifyEmail(_, _, environment),
             let .agreeTerms(_, _, environment),
             let .completeOnboarding(_, _, environment),
             let .completeLandlordOnboarding(_, _, environment):
            environment
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case let .socialLogin(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .reissue(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .logout(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .sendPhoneVerificationCode(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .verifyPhone(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .sendEmailVerificationCode(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .verifyEmail(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .agreeTerms(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .completeOnboarding(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .completeLandlordOnboarding(requestDTO, accessToken, _):
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)
        }

        return request
    }
}
