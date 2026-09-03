//
//  AppDelegate.swift
//  Kohere
//
//  Created by 송규섭 on 9/4/26.
//

import FirebaseCore
import FirebaseMessaging
import OSLog
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.kohere.Kohere", category: "Push")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = FCMTokenRelay.shared
        return true
    }

    /// APNs 기기 토큰 발급 성공 시 Firebase에 전달한다.
    /// FCM은 이 토큰을 받아야 FCM 등록 토큰을 발급·갱신할 수 있다.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        logger.info("event=apns_token_received")
        Messaging.messaging().apnsToken = deviceToken

        // delegate 콜백이 오지 않는 환경 대비: APNs 토큰 확보 직후 FCM 토큰을 직접 조회해
        // 같은 스트림(FCMTokenRelay)으로 흘려보낸다. (deprecated 경고는 대체 API 확정 전까지 감수)
        Messaging.messaging().token { [logger] fcmToken, error in
            if let error {
                logger.error("event=fcm_token_fetch_failed error=\(error.localizedDescription, privacy: .public)")
                return
            }

            guard let fcmToken else { return }

            logger.info("event=fcm_token_fetched")
            FCMTokenRelay.shared.emit(fcmToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("event=apns_register_failed error=\(error.localizedDescription, privacy: .public)")
    }
}
