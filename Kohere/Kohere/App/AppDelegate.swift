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
        return true
    }

    /// APNs 기기 토큰 발급 성공 시 Firebase에 전달한다.
    /// FCM은 이 토큰을 받아야 FCM 등록 토큰을 발급·갱신할 수 있다.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("event=apns_register_failed error=\(error.localizedDescription, privacy: .public)")
    }
}
