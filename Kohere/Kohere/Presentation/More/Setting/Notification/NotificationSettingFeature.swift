//
//  NotificationSettingFeature.swift
//  Kohere
//

import ComposableArchitecture

@Reducer
struct NotificationSettingFeature {
    @Dependency(\.userClient)
    var userClient
    @Dependency(\.pushNotificationClient)
    var pushNotificationClient

    @ObservableState
    struct State: Equatable {
        var userType: UserType
        var language: AppLanguage = .english

        /// 마지막으로 서버에서 확인한 계정 전체의 설정. 조회 전에는 값을 추측하지 않는다.
        var serverChatPushEnabled: Bool?
        /// PATCH 응답을 기다리는 동안에만 화면에 반영하는 값.
        var optimisticChatPushEnabled: Bool?
        var authorization: NotificationAuthorization?
        var loadState: LoadState = .idle
        var loadGeneration = 0

        var isCheckingAuthorization = false
        var isOpeningSettings = false
        var isAwaitingSettingsReturn = false
        var shouldEnableAfterPermission = false
        var needsReloadAfterSave = false

        var isSaving: Bool { optimisticChatPushEnabled != nil }
        var isLoading: Bool {
            loadState == .idle || loadState == .loading || isCheckingAuthorization
        }
        var showsSkeleton: Bool {
            guard let authorization else { return true }
            return authorization.allowsNotifications && serverChatPushEnabled == nil
        }
        var isChatPushEnabled: Bool {
            guard authorization?.allowsNotifications == true else { return false }
            return optimisticChatPushEnabled ?? serverChatPushEnabled ?? false
        }
        var canInteractWithToggle: Bool {
            guard let authorization, !isSaving, !isCheckingAuthorization,
                  !isOpeningSettings, !isAwaitingSettingsReturn else { return false }
            // 시스템 차단은 서버 조회를 기다리지 않고 OFF 및 권한 안내 동작을 제공한다.
            return !authorization.allowsNotifications
                || (loadState == .loaded && serverChatPushEnabled != nil)
        }
    }

    enum LoadState: Equatable {
        case idle, loading, loaded, failed
    }

    enum Action: Equatable {
        case task
        case willEnterForeground
        case backButtonTapped
        case retryButtonTapped
        case chatPushEnabledChanged(Bool)
        case preferencesResponse(Int, Result<Bool, DataError>)
        case updateResponse(Result<Bool, DataError>)
        case authorizationResponse(NotificationAuthorization, requestedByUser: Bool)
        case authorizationRequestFailed
        case openSystemSettingsTapped
        case systemSettingsOpened(Bool)
        case pushRegistrationRequested
        case popupRequested(AppPopup)
    }

    nonisolated enum CancelID { case load, authorization, update, openSettings }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                guard state.loadState == .idle else { return .none }
                return .merge(loadPreferences(state: &state), checkAuthorization(state: &state))

            case .willEnterForeground:
                state.isAwaitingSettingsReturn = false
                let permissionEffect = checkAuthorization(state: &state)
                // PATCH 도중 GET이 먼저 끝나 예전 값으로 덮어쓰는 것을 방지한다.
                if state.isSaving {
                    state.needsReloadAfterSave = true
                    return permissionEffect
                }
                return .merge(permissionEffect, loadPreferences(state: &state))

            case .retryButtonTapped:
                return .merge(loadPreferences(state: &state), checkAuthorization(state: &state))

            case let .preferencesResponse(generation, result):
                guard generation == state.loadGeneration, state.loadState == .loading,
                      !state.isSaving else { return .none }
                switch result {
                case let .success(isEnabled):
                    state.serverChatPushEnabled = isEnabled
                    state.loadState = .loaded
                    return finishPendingEnable(state: &state)
                case .failure:
                    state.loadState = .failed
                    state.shouldEnableAfterPermission = false
                    return .send(.popupRequested(Self.loadFailurePopup(language: state.language)))
                }

            case let .authorizationResponse(authorization, requestedByUser):
                state.isCheckingAuthorization = false
                state.authorization = authorization
                if !authorization.allowsNotifications {
                    state.shouldEnableAfterPermission = false
                    return .none
                }
                let enableEffect = finishPendingEnable(state: &state)
                return requestedByUser
                    ? .merge(enableEffect, .send(.pushRegistrationRequested))
                    : enableEffect

            case .authorizationRequestFailed:
                state.isCheckingAuthorization = false
                state.shouldEnableAfterPermission = false
                return .send(.popupRequested(Self.permissionFailurePopup(language: state.language)))

            case let .chatPushEnabledChanged(isEnabled):
                guard state.canInteractWithToggle else { return .none }
                switch state.authorization {
                case .authorized, .provisional, .ephemeral:
                    return savePreference(isEnabled, state: &state)
                case .notDetermined:
                    // 로그인에서 이미 요청하는 것이 정상 흐름이며, 미결정 상태만 예외 처리한다.
                    state.shouldEnableAfterPermission = true
                    state.isCheckingAuthorization = true
                    return requestAuthorization()
                case .denied:
                    return .send(.popupRequested(Self.permissionPopup(language: state.language)))
                case .unknown, nil:
                    return .send(.popupRequested(Self.permissionFailurePopup(language: state.language)))
                }

            case .openSystemSettingsTapped:
                guard !state.isOpeningSettings, !state.isSaving else { return .none }
                // 명시적으로 켜려던 의도만 설정 복귀 시 이어간다.
                state.shouldEnableAfterPermission = true
                state.isAwaitingSettingsReturn = true
                state.isOpeningSettings = true
                return .run { [pushNotificationClient] send in
                    let opened = await pushNotificationClient.openNotificationSettings()
                    guard !Task.isCancelled else { return }
                    await send(.systemSettingsOpened(opened))
                }
                .cancellable(id: CancelID.openSettings, cancelInFlight: true)

            case let .systemSettingsOpened(opened):
                state.isOpeningSettings = false
                guard !opened else { return .none }
                state.isAwaitingSettingsReturn = false
                state.shouldEnableAfterPermission = false
                return .send(.popupRequested(.notice(AppPopup.Notice(
                    message: state.language.localized(.settingsNotificationSettingsOpenFailure),
                    confirmTitle: state.language.localized(.commonConfirm)
                ))))

            case let .updateResponse(result):
                guard state.isSaving else { return .none }
                state.optimisticChatPushEnabled = nil
                let needsReload = state.needsReloadAfterSave
                state.needsReloadAfterSave = false
                switch result {
                case let .success(isEnabled):
                    state.serverChatPushEnabled = isEnabled
                    return needsReload ? loadPreferences(state: &state) : .none
                case .failure:
                    // 응답 유실로 서버에는 반영됐을 수 있으므로 복구 후 GET도 재실행한다.
                    return .merge(
                        .send(.popupRequested(Self.saveFailurePopup(language: state.language))),
                        loadPreferences(state: &state)
                    )
                }

            case .backButtonTapped, .popupRequested, .pushRegistrationRequested:
                return .none
            }
        }
    }
}

private extension NotificationSettingFeature {
    func loadPreferences(state: inout State) -> Effect<Action> {
        guard !state.isSaving, state.loadState != .loading else { return .none }
        state.loadState = .loading
        state.loadGeneration += 1
        let generation = state.loadGeneration
        return .run { [userClient] send in
            do {
                let isEnabled = try await userClient.fetchChatPushEnabled()
                try Task.checkCancellation()
                await send(.preferencesResponse(generation, .success(isEnabled)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.preferencesResponse(generation, .failure(.from(error))))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    func checkAuthorization(state: inout State) -> Effect<Action> {
        guard !state.isCheckingAuthorization else { return .none }
        state.isCheckingAuthorization = true
        return .run { [pushNotificationClient] send in
            let status = await pushNotificationClient.authorizationStatus()
            guard !Task.isCancelled else { return }
            await send(.authorizationResponse(status, requestedByUser: false))
        }
        .cancellable(id: CancelID.authorization, cancelInFlight: true)
    }

    func requestAuthorization() -> Effect<Action> {
        .run { [pushNotificationClient] send in
            do {
                _ = try await pushNotificationClient.requestAuthorization()
                let status = await pushNotificationClient.authorizationStatus()
                try Task.checkCancellation()
                await send(.authorizationResponse(status, requestedByUser: true))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.authorizationRequestFailed)
            }
        }
        .cancellable(id: CancelID.authorization, cancelInFlight: true)
    }

    func finishPendingEnable(state: inout State) -> Effect<Action> {
        guard state.shouldEnableAfterPermission, !state.isAwaitingSettingsReturn,
              !state.isCheckingAuthorization, state.authorization?.allowsNotifications == true,
              state.loadState == .loaded else { return .none }
        state.shouldEnableAfterPermission = false
        return savePreference(true, state: &state)
    }

    func savePreference(_ isEnabled: Bool, state: inout State) -> Effect<Action> {
        guard !state.isSaving, state.loadState == .loaded,
              let current = state.serverChatPushEnabled, current != isEnabled else { return .none }
        state.optimisticChatPushEnabled = isEnabled
        return .run { [userClient] send in
            do {
                let savedValue = try await userClient.updateChatPushEnabled(isEnabled)
                try Task.checkCancellation()
                await send(.updateResponse(.success(savedValue)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.updateResponse(.failure(.from(error))))
            }
        }
        .cancellable(id: CancelID.update, cancelInFlight: true)
    }

    static func loadFailurePopup(language: AppLanguage) -> AppPopup {
        .action(AppPopup.Action(
            message: language.localized(.settingsNotificationLoadFailureMessage),
            primaryTitle: language.localized(.settingsNotificationLoadFailureRetry),
            secondaryTitle: language.localized(.settingsNotificationLoadFailureBack),
            primaryRoute: .retryNotificationSettings,
            secondaryRoute: .dismissNotificationSettings
        ))
    }

    static func permissionPopup(language: AppLanguage) -> AppPopup {
        .action(AppPopup.Action(
            message: language.localized(.settingsNotificationPermissionMessage),
            primaryTitle: language.localized(.settingsNotificationPermissionOpenSettings),
            secondaryTitle: language.localized(.commonCancel),
            primaryRoute: .openNotificationSettings
        ))
    }

    static func permissionFailurePopup(language: AppLanguage) -> AppPopup {
        .notice(AppPopup.Notice(
            message: language.localized(.settingsNotificationPermissionFailure),
            confirmTitle: language.localized(.commonConfirm)
        ))
    }

    static func saveFailurePopup(language: AppLanguage) -> AppPopup {
        .notice(AppPopup.Notice(
            message: language.localized(.settingsNotificationSaveFailure),
            confirmTitle: language.localized(.commonConfirm)
        ))
    }
}
