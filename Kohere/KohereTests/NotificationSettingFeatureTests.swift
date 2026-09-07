import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class NotificationSettingFeatureTests: XCTestCase {
    func testInitialLoadKeepsSkeletonUntilServerValueArrives() async {
        let clock = TestClock()
        let store = makeStore(state: .init(userType: .tenant), fetch: {
            try await clock.sleep(for: .seconds(1))
            return false
        })

        await store.send(.task) {
            $0.loadState = .loading
            $0.loadGeneration = 1
            $0.isCheckingAuthorization = true
        }
        XCTAssertTrue(store.state.showsSkeleton)
        XCTAssertFalse(store.state.canInteractWithToggle)
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.authorization = .authorized
            $0.isCheckingAuthorization = false
        }
        XCTAssertTrue(store.state.showsSkeleton)
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) {
            $0.serverChatPushEnabled = false
            $0.loadState = .loaded
        }
        XCTAssertFalse(store.state.showsSkeleton)
        XCTAssertFalse(store.state.isChatPushEnabled)
        XCTAssertTrue(store.state.canInteractWithToggle)
    }

    func testDeniedPermissionShowsOffWithoutChangingAccountSetting() async {
        let clock = TestClock()
        let store = makeStore(state: .init(userType: .tenant, language: .korean), fetch: {
            try await clock.sleep(for: .seconds(1))
            return true
        }, authorization: { .denied })

        await store.send(.task) {
            $0.loadState = .loading
            $0.loadGeneration = 1
            $0.isCheckingAuthorization = true
        }
        await store.receive(.authorizationResponse(.denied, requestedByUser: false)) {
            $0.authorization = .denied
            $0.isCheckingAuthorization = false
        }
        XCTAssertFalse(store.state.showsSkeleton)
        XCTAssertFalse(store.state.isChatPushEnabled)
        await store.send(.chatPushEnabledChanged(true))
        await store.receive(.popupRequested(.action(AppPopup.Action(
            message: AppLanguage.korean.localized(.settingsNotificationPermissionMessage),
            primaryTitle: AppLanguage.korean.localized(.settingsNotificationPermissionOpenSettings),
            secondaryTitle: AppLanguage.korean.localized(.commonCancel),
            primaryRoute: .openNotificationSettings
        ))))
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: true)))) {
            $0.serverChatPushEnabled = true
            $0.loadState = .loaded
        }
        XCTAssertEqual(store.state.serverChatPushEnabled, true)
        XCTAssertFalse(store.state.isChatPushEnabled)
        // Unexpected PATCH / permission request / Settings opening fails through the test dependencies.
    }

    func testOptimisticSaveIgnoresDuplicateTapAndUsesResponseValue() async {
        let clock = TestClock()
        let sentValues = LockIsolated<[Bool]>([])
        let store = makeStore(update: { value in
            sentValues.withValue { $0.append(value) }
            try await clock.sleep(for: .seconds(1))
            return true // Server's final value takes precedence over the submitted false.
        })

        await store.send(.chatPushEnabledChanged(false)) { $0.optimisticChatPushEnabled = false }
        XCTAssertFalse(store.state.isChatPushEnabled)
        XCTAssertFalse(store.state.canInteractWithToggle)
        await store.send(.chatPushEnabledChanged(true))
        await clock.advance(by: .seconds(1))
        await store.receive(.updateResponse(.success(.init(chatPushEnabled: true)))) { $0.optimisticChatPushEnabled = nil }
        XCTAssertEqual(sentValues.value, [false])
        XCTAssertTrue(store.state.isChatPushEnabled)
        XCTAssertTrue(store.state.canInteractWithToggle)
    }

    func testFailedSaveRollsBackThenReconcilesPotentiallyCommittedServerValue() async {
        let clock = TestClock()
        let failure = DataError.transport(message: "Response lost")
        let store = makeStore(fetch: {
            try await clock.sleep(for: .seconds(1))
            return false
        }, update: { _ in throw failure })

        await store.send(.chatPushEnabledChanged(false)) { $0.optimisticChatPushEnabled = false }
        await store.receive(.updateResponse(.failure(.requestFailed(failure)))) {
            $0.optimisticChatPushEnabled = nil
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        XCTAssertTrue(store.state.isChatPushEnabled)
        XCTAssertFalse(store.state.showsSkeleton)
        XCTAssertFalse(store.state.canInteractWithToggle)
        await store.receive(\.popupRequested)
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) {
            $0.serverChatPushEnabled = false
            $0.loadState = .loaded
        }
        XCTAssertFalse(store.state.isChatPushEnabled)
    }

    func testFailedSaveAndReconciliationKeepRollbackAndOfferExit() async {
        let clock = TestClock()
        let failure = DataError.transport(message: "Offline")
        let store = makeStore(fetch: {
            try await clock.sleep(for: .seconds(1))
            throw failure
        }, update: { _ in throw failure })

        await store.send(.chatPushEnabledChanged(false)) { $0.optimisticChatPushEnabled = false }
        await store.receive(.updateResponse(.failure(.requestFailed(failure)))) {
            $0.optimisticChatPushEnabled = nil
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        await store.receive(.popupRequested(.notice(AppPopup.Notice(
            message: AppLanguage.english.localized(.settingsNotificationSaveFailure),
            confirmTitle: AppLanguage.english.localized(.commonConfirm)
        ))))
        XCTAssertTrue(store.state.isChatPushEnabled)
        XCTAssertFalse(store.state.showsSkeleton)
        XCTAssertFalse(store.state.canInteractWithToggle)

        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .failure(.requestFailed(failure)))) {
            $0.loadState = .failed
        }
        await store.receive(.popupRequested(.notice(AppPopup.Notice(
            message: AppLanguage.english.localized(.settingsNotificationLoadFailureMessage),
            confirmTitle: AppLanguage.english.localized(.commonConfirm),
            confirmRoute: .dismissNotificationSettings,
            confirmStyle: .primary
        ))))
        XCTAssertEqual(store.state.serverChatPushEnabled, true)
        XCTAssertNil(store.state.optimisticChatPushEnabled)
        XCTAssertFalse(store.state.canInteractWithToggle)
        await store.finish()
    }

    func testForegroundDefersGetUntilPendingPatchCompletes() async {
        let clock = TestClock()
        let fetchCount = LockIsolated(0)
        let store = makeStore(fetch: {
            fetchCount.withValue { $0 += 1 }
            return false
        }, update: { value in
            try await clock.sleep(for: .seconds(1))
            return value
        })

        await store.send(.chatPushEnabledChanged(false)) { $0.optimisticChatPushEnabled = false }
        await store.send(.willEnterForeground) {
            $0.isCheckingAuthorization = true
            $0.needsReloadAfterSave = true
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.isCheckingAuthorization = false
        }
        XCTAssertEqual(fetchCount.value, 0)
        await clock.advance(by: .seconds(1))
        await store.receive(.updateResponse(.success(.init(chatPushEnabled: false)))) {
            $0.optimisticChatPushEnabled = nil
            $0.serverChatPushEnabled = false
            $0.needsReloadAfterSave = false
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) { $0.loadState = .loaded }
        XCTAssertEqual(fetchCount.value, 1)
    }

    func testOrdinaryForegroundDoesNotEnableServerPreference() async {
        let clock = TestClock()
        let store = makeStore(state: loadedState(enabled: false, authorization: .denied), fetch: {
            try await clock.sleep(for: .seconds(1))
            return false
        })

        await store.send(.willEnterForeground) {
            $0.isCheckingAuthorization = true
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.authorization = .authorized
            $0.isCheckingAuthorization = false
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) { $0.loadState = .loaded }
        XCTAssertFalse(store.state.isChatPushEnabled)
    }

    func testExplicitSettingsRoundTripEnablesOnlyAfterPermissionAndGetComplete() async {
        let clock = TestClock()
        let sentValues = LockIsolated<[Bool]>([])
        let store = makeStore(state: loadedState(enabled: false, authorization: .denied), fetch: {
            try await clock.sleep(for: .seconds(1))
            return false
        }, update: { value in
            sentValues.withValue { $0.append(value) }
            return value
        }, openSettings: { true })

        await store.send(.openSystemSettingsTapped) {
            $0.shouldEnableAfterPermission = true
            $0.isAwaitingSettingsReturn = true
            $0.isOpeningSettings = true
        }
        await store.receive(.systemSettingsOpened(true)) { $0.isOpeningSettings = false }
        XCTAssertFalse(store.state.canInteractWithToggle)
        await store.send(.willEnterForeground) {
            $0.isAwaitingSettingsReturn = false
            $0.isCheckingAuthorization = true
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.authorization = .authorized
            $0.isCheckingAuthorization = false
        }
        XCTAssertEqual(sentValues.value, [])
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) {
            $0.loadState = .loaded
            $0.shouldEnableAfterPermission = false
            $0.optimisticChatPushEnabled = true
        }
        await store.receive(.updateResponse(.success(.init(chatPushEnabled: true)))) {
            $0.optimisticChatPushEnabled = nil
            $0.serverChatPushEnabled = true
        }
        XCTAssertEqual(sentValues.value, [true])
    }

    func testReturningWithoutPermissionClearsEnableIntent() async {
        let clock = TestClock()
        var initial = loadedState(enabled: false, authorization: .denied)
        initial.shouldEnableAfterPermission = true
        initial.isAwaitingSettingsReturn = true
        let store = makeStore(state: initial, fetch: {
            try await clock.sleep(for: .seconds(1))
            return false
        }, authorization: { .denied })

        await store.send(.willEnterForeground) {
            $0.isAwaitingSettingsReturn = false
            $0.isCheckingAuthorization = true
            $0.loadState = .loading
            $0.loadGeneration = 1
        }
        await store.receive(.authorizationResponse(.denied, requestedByUser: false)) {
            $0.isCheckingAuthorization = false
            $0.shouldEnableAfterPermission = false
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) { $0.loadState = .loaded }
        XCTAssertFalse(store.state.isChatPushEnabled)
    }

    func testNotDeterminedRequestsPermissionOnTapAndResumesPushRegistration() async {
        let requestCount = LockIsolated(0)
        let clock = TestClock()
        let store = makeStore(state: loadedState(enabled: false, authorization: .notDetermined),
                              update: { value in
            try await clock.sleep(for: .seconds(1))
            return value
        }, request: {
            requestCount.withValue { $0 += 1 }
            return true
        })

        await store.send(.chatPushEnabledChanged(true)) {
            $0.shouldEnableAfterPermission = true
            $0.isCheckingAuthorization = true
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: true)) {
            $0.authorization = .authorized
            $0.isCheckingAuthorization = false
            $0.shouldEnableAfterPermission = false
            $0.optimisticChatPushEnabled = true
        }
        await store.receive(.pushRegistrationRequested)
        await clock.advance(by: .seconds(1))
        await store.receive(.updateResponse(.success(.init(chatPushEnabled: true)))) {
            $0.optimisticChatPushEnabled = nil
            $0.serverChatPushEnabled = true
        }
        XCTAssertEqual(requestCount.value, 1)
    }

    func testLoadFailureUsesNoticeAndForegroundReloadIgnoresStaleResponse() async {
        let clock = TestClock()
        let fetchCount = LockIsolated(0)
        let failure = DataError.transport(message: "Offline")
        let store = makeStore(state: .init(userType: .tenant), fetch: {
            let attempt = fetchCount.withValue { $0 += 1; return $0 }
            try await clock.sleep(for: .seconds(1))
            if attempt == 1 { throw failure }
            return true
        })
        await store.send(.task) {
            $0.loadState = .loading
            $0.loadGeneration = 1
            $0.isCheckingAuthorization = true
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.authorization = .authorized
            $0.isCheckingAuthorization = false
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(1, .failure(.requestFailed(failure)))) { $0.loadState = .failed }
        await store.receive(.popupRequested(.notice(AppPopup.Notice(
            message: AppLanguage.english.localized(.settingsNotificationLoadFailureMessage),
            confirmTitle: AppLanguage.english.localized(.commonConfirm),
            confirmRoute: .dismissNotificationSettings,
            confirmStyle: .primary
        ))))
        XCTAssertTrue(store.state.showsSkeleton)
        XCTAssertFalse(store.state.isLoading)

        await store.send(.willEnterForeground) {
            $0.loadState = .loading
            $0.loadGeneration = 2
            $0.isCheckingAuthorization = true
        }
        await store.receive(.authorizationResponse(.authorized, requestedByUser: false)) {
            $0.isCheckingAuthorization = false
        }
        await store.send(.preferencesResponse(1, .success(.init(chatPushEnabled: false)))) // Stale result cannot replace this retry.
        await clock.advance(by: .seconds(1))
        await store.receive(.preferencesResponse(2, .success(.init(chatPushEnabled: true)))) {
            $0.serverChatPushEnabled = true
            $0.loadState = .loaded
        }
        XCTAssertEqual(fetchCount.value, 2)
    }

    func testLoadFailureConfirmationDismissesPopupAndReturnsToSettings() async {
        var state = RootFeature.State()
        state.selectedTab = .more
        state.more.path.append(.setting(SettingFeature.State()))
        state.more.path.append(.notificationSetting(.init(userType: .tenant, loadState: .failed)))
        state.popup = .notice(AppPopup.Notice(
            message: AppLanguage.english.localized(.settingsNotificationLoadFailureMessage),
            confirmTitle: AppLanguage.english.localized(.commonConfirm),
            confirmRoute: .dismissNotificationSettings,
            confirmStyle: .primary
        ))
        let store = TestStore(initialState: state) { RootFeature() }

        await store.send(.popupNoticeConfirmButtonTapped) { $0.popup = nil }
        await store.receive(\.more.notificationSettingsDismissRequested)
        await store.receive(\.more.path) { _ = $0.more.path.popLast() }
        XCTAssertEqual(store.state.more.path.count, 1)
        XCTAssertNotNil(store.state.more.path.last?.setting)
        await store.finish()
    }

    private func loadedState(enabled: Bool = true,
                             authorization: NotificationAuthorization = .authorized) -> NotificationSettingFeature.State {
        .init(userType: .tenant, serverChatPushEnabled: enabled,
              authorization: authorization, loadState: .loaded)
    }

    private func makeStore(
        state: NotificationSettingFeature.State? = nil,
        fetch: @escaping @Sendable () async throws -> Bool = {
            XCTFail("Unexpected preferences GET"); throw DataError.emptyResponse
        },
        update: @escaping @Sendable (Bool) async throws -> Bool = { _ in
            XCTFail("Unexpected preferences PATCH"); throw DataError.emptyResponse
        },
        authorization: @escaping @Sendable () async -> NotificationAuthorization = { .authorized },
        openSettings: @escaping @Sendable () async -> Bool = {
            XCTFail("Unexpected Settings opening"); return false
        },
        request: @escaping @Sendable () async throws -> Bool = {
            XCTFail("Unexpected system permission request"); return false
        }
    ) -> TestStore<NotificationSettingFeature.State, NotificationSettingFeature.Action> {
        TestStore(initialState: state ?? loadedState()) {
            NotificationSettingFeature()
        } withDependencies: {
            $0.userClient = UserClient(
                fetchCurrentUser: { XCTFail("Unexpected users/me"); throw DataError.emptyResponse },
                fetchNotificationPreferences: { .init(chatPushEnabled: try await fetch()) },
                updateNotificationPreferences: { .init(chatPushEnabled: try await update($0)) },
                updateProfile: { _ in XCTFail("Unexpected profile PATCH"); throw DataError.emptyResponse },
                deleteCurrentUser: { XCTFail("Unexpected account deletion") }
            )
            $0.pushNotificationClient = PushNotificationClient(
                authorizationStatus: authorization,
                openNotificationSettings: openSettings,
                requestAuthorization: request,
                registerForRemoteNotifications: { XCTFail("Page must delegate APNs registration to Root") },
                fcmTokenUpdates: { XCTFail("Page must delegate FCM observation to Root"); return .finished }
            )
        }
    }
}
