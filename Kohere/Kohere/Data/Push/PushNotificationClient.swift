//
//  PushNotificationClient.swift
//  Kohere
//
//  Created by 송규섭 on 9/4/26.
//

import ComposableArchitecture
import FirebaseMessaging
import os
import OSLog
import UIKit
import UserNotifications

struct PushNotificationClient: Sendable {
    /// 권한 팝업을 띄우지 않고 현재 기기의 알림 권한을 조회한다.
    var authorizationStatus: @Sendable () async -> NotificationAuthorization
    /// iOS의 이 앱 알림 설정으로 이동한다.
    var openNotificationSettings: @Sendable () async -> Bool
    /// 시스템 알림 권한을 요청한다. 시스템 팝업은 앱 수명 동안 최초 1회만 뜬다.
    var requestAuthorization: @Sendable () async throws -> Bool
    /// APNs 원격 알림 등록을 시작한다. 발급된 기기 토큰은 AppDelegate를 거쳐 FCM에 전달된다.
    var registerForRemoteNotifications: @Sendable () async -> Void
    /// FCM 토큰 발급·갱신 이벤트 스트림. 토큰이 바뀔 때마다 서버 재등록에 사용한다.
    var fcmTokenUpdates: @Sendable () -> AsyncStream<String>
}

extension PushNotificationClient: DependencyKey {
    static let liveValue = PushNotificationClient(
        authorizationStatus: {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .authorized: return .authorized
            case .provisional: return .provisional
            case .ephemeral: return .ephemeral
            @unknown default: return .unknown
            }
        },
        openNotificationSettings: {
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return false }
            return await UIApplication.shared.open(url)
        },
        requestAuthorization: {
            try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        },
        registerForRemoteNotifications: {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        },
        fcmTokenUpdates: {
            FCMTokenRelay.shared.updates()
        }
    )
}

extension DependencyValues {
    var pushNotificationClient: PushNotificationClient {
        get { self[PushNotificationClient.self] }
        set { self[PushNotificationClient.self] = newValue }
    }
}

/// MessagingDelegate 콜백(토큰 발급·갱신)을 AsyncStream으로 중계한다.
/// AppDelegate에서 `Messaging.messaging().delegate`로 등록된다.
nonisolated final class FCMTokenRelay: NSObject, MessagingDelegate, @unchecked Sendable {
    static let shared = FCMTokenRelay()

    private let logger = Logger(subsystem: "com.kohere.Kohere", category: "Push")

    private struct Subscriptions {
        var lastToken: String?
        var continuations: [UUID: AsyncStream<String>.Continuation] = [:]
    }

    private let subscriptions = OSAllocatedUnfairLock<Subscriptions>(initialState: Subscriptions())

    func updates() -> AsyncStream<String> {
        AsyncStream { continuation in
            let id = UUID()

            subscriptions.withLock { state in
                state.continuations[id] = continuation

                let hasCachedToken = state.lastToken != nil
                logger.info("event=fcm_stream_subscribed hasCachedToken=\(hasCachedToken)")

                // 구독 이전에 이미 발급된 토큰이 있으면 즉시 재생해 놓치지 않게 한다.
                if let lastToken = state.lastToken {
                    continuation.yield(lastToken)
                }
            }

            continuation.onTermination = { [weak self] _ in
                self?.subscriptions.withLock { $0.continuations[id] = nil }
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        logger.info("event=fcm_delegate_fired hasToken=\(fcmToken != nil)")
        guard let fcmToken else { return }

        emit(fcmToken)
    }

    /// delegate 콜백 외의 경로(명시적 토큰 조회 등)로 확보한 토큰을 같은 스트림으로 흘려보낸다.
    func emit(_ fcmToken: String) {
        subscriptions.withLock { state in
            state.lastToken = fcmToken

            for continuation in state.continuations.values {
                continuation.yield(fcmToken)
            }
        }
    }
}
