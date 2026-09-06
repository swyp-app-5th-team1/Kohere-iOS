//
//  NotificationAuthorization.swift
//  Kohere
//

/// 현재 기기의 iOS 알림 권한. 계정 전체에 적용되는 서버 수신 설정과 별개다.
nonisolated enum NotificationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    case unknown

    var allowsNotifications: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied, .unknown:
            false
        }
    }
}
