//
//  UserNotificationPreferences.swift
//  Kohere
//

/// 같은 계정의 모든 기기에 적용되는 서버 알림 설정. iOS 기기 권한과는 별개다.
nonisolated struct UserNotificationPreferences: Equatable, Sendable {
    let chatPushEnabled: Bool
}
