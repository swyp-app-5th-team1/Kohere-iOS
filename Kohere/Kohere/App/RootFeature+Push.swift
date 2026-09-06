//
//  RootFeature+Push.swift
//  Kohere
//
//  Created by 송규섭 on 9/4/26.
//

import ComposableArchitecture
import Foundation
import OSLog

private enum PushRegistrationLogger {
    nonisolated static let value = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.kohere.Kohere",
        category: "PushRegistration"
    )
}

extension RootFeature {
    static let pushTokenObserverID = "RootFeature.pushTokenObserver"

    /// 로그인에서는 권한을 요청하고, 앱 복귀에서는 현재 권한만 확인한다.
    /// 허용 시 APNs 등록을 시작한 뒤 FCM 토큰 스트림을 구독한다.
    /// 토큰이 발급·갱신될 때마다 `.fcmTokenReceived`로 전달된다.
    func startPushRegistration(requestPermission: Bool = true) -> Effect<Action> {
        let pushNotificationClient = pushNotificationClient

        return .run { send in
            let granted: Bool
            if requestPermission {
                granted = (try? await pushNotificationClient.requestAuthorization()) ?? false
            } else {
                granted = await pushNotificationClient.authorizationStatus().allowsNotifications
            }
            guard !Task.isCancelled else { return }
            guard granted else {
                PushRegistrationLogger.value.info("event=push_authorization_denied")
                return
            }

            PushRegistrationLogger.value.info("event=push_authorization_granted")
            await pushNotificationClient.registerForRemoteNotifications()

            for await token in pushNotificationClient.fcmTokenUpdates() {
                guard !Task.isCancelled else { return }
                await send(.fcmTokenReceived(token))
            }
        }
        .cancellable(id: Self.pushTokenObserverID, cancelInFlight: true)
    }

    /// 현재 설치본의 FCM 토큰을 서버에 등록·갱신한다.
    func registerPushDevice(fcmToken: String) -> Effect<Action> {
        let pushDeviceClient = pushDeviceClient
        let installationIdClient = installationIdClient

        return .run { _ in
            #if DEBUG
            // 개발 중 백엔드 발송 테스트용. 배포 빌드에는 포함되지 않는다.
            PushRegistrationLogger.value.info("event=fcm_token_received token=\(fcmToken, privacy: .public)")
            #endif

            do {
                let installationId = try installationIdClient.id()
                try await pushDeviceClient.registerDevice(installationId, fcmToken)
                PushRegistrationLogger.value.info("event=push_device_registered")
            } catch {
                PushRegistrationLogger.value.error(
                    "event=push_device_register_failed error=\(error.localizedDescription, privacy: .public)"
                )
            }
        }
        .cancellable(id: "RootFeature.pushDeviceRegister", cancelInFlight: true)
    }
}
