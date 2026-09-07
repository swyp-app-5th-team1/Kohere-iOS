//
//  NotificationSettingError.swift
//  Kohere
//

/// 공통 네트워크 처리 이후 알림 설정 Repository 경계에서 사용하는 오류.
enum NotificationSettingError: Error, Equatable {
    case invalidInput
    case malformedRequest
    case unauthenticated
    case tokenExpired
    case onboardingRequired
    /// 명세에 없는 서버 오류나 통신 실패는 원인을 잃지 않도록 보존한다.
    case requestFailed(DataError)

    static func from(_ error: Error) -> Self {
        if let error = error as? Self { return error }

        let dataError = DataError.from(error)
        guard case let .serverError(code, _) = dataError else {
            return .requestFailed(dataError)
        }

        switch code {
        case "INVALID_INPUT": return .invalidInput
        case "MALFORMED_REQUEST": return .malformedRequest
        case "UNAUTHENTICATED": return .unauthenticated
        case "TOKEN_EXPIRED": return .tokenExpired
        case "AUTH_ONBOARDING_REQUIRED": return .onboardingRequired
        default: return .requestFailed(dataError)
        }
    }
}
