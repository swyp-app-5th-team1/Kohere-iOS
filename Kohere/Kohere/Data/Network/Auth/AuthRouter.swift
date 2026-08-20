//
//  AuthRouter.swift
//  Kohere
//
//  Created by soomin on 6/30/26.
//

import Alamofire
import Foundation

enum AuthRouter: URLRequestConvertible {
    case socialLogin(SocialLoginRequestDTO, APIEnvironment)
    case reissue(ReissueTokenRequestDTO, APIEnvironment)
    case logout(LogoutRequestDTO, APIEnvironment)
    case sendPhoneVerificationCode(
        PhoneVerificationCodeRequestDTO,
        APIEnvironment
    )
    case verifyPhone(
        PhoneVerificationRequestDTO,
        APIEnvironment
    )
    case sendEmailVerificationCode(
        EmailVerificationCodeRequestDTO,
        APIEnvironment
    )
    case verifyEmail(
        EmailVerificationRequestDTO,
        APIEnvironment
    )
    case agreeTerms(
        TermsAgreementRequestDTO,
        APIEnvironment
    )
    case completeOnboarding(
        AuthOnboardingRequestDTO,
        APIEnvironment
    )
    case completeLandlordOnboarding(
        LandlordOnboardingRequestDTO,
        APIEnvironment
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
             let .logout(_, environment),
             let .sendPhoneVerificationCode(_, environment),
             let .verifyPhone(_, environment),
             let .sendEmailVerificationCode(_, environment),
             let .verifyEmail(_, environment),
             let .agreeTerms(_, environment),
             let .completeOnboarding(_, environment),
             let .completeLandlordOnboarding(_, environment):
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

        case let .logout(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .sendPhoneVerificationCode(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .verifyPhone(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .sendEmailVerificationCode(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .verifyEmail(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .agreeTerms(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .completeOnboarding(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .completeLandlordOnboarding(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)
        }

        return request
    }
}
