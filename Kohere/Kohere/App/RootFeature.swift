//
//  RootFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RootFeature {
    @Dependency(\.keychainClient)
    var keychainClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient
    @Dependency(\.reissueTokenUseCase)
    var reissueTokenUseCase
    @Dependency(\.logoutUseCase)
    var logoutUseCase
    @Dependency(\.fetchCurrentUserUseCase)
    var fetchCurrentUserUseCase
    @Dependency(\.deleteCurrentUserUseCase)
    var deleteCurrentUserUseCase
    
    @ObservableState
    struct State: Equatable {
        var authInfo: Auth?
        var currentUser: UserProfile?
        var isAuthLoading = true
        var isCurrentUserLoading = false
        var login = LoginFeature.State()
        var onboarding = OnboardingFeature.State()
        var selectedTab: AppTab = .home
        var popup: AppPopup?
        var home = HomeFeature.State()
        var community = CommunityFeature.State()
        var map = MapFeature.State()
        var chat = ChatFeature.State()
        var more = MoreFeature.State()
    }
    
    enum Action {
        case onAppear
        case mainTabAppeared
        case storedAuthLoaded(Auth?, OnboardingUserType?)
        case authSessionExpired
        case currentUserResponse(Result<UserProfile, Error>)
        case login(LoginFeature.Action)
        case saveAuthResponse(Result<Auth, Error>)
        case onboarding(OnboardingFeature.Action)
        case selectedTabChanged(AppTab)
        case popupPresented(AppPopup)
        case popupNoticeConfirmButtonTapped
        case popupActionPrimaryButtonTapped
        case popupActionSecondaryButtonTapped
        case home(HomeFeature.Action)
        case community(CommunityFeature.Action)
        case map(MapFeature.Action)
        case chat(ChatFeature.Action)
        case more(MoreFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.community, action: \.community) {
            CommunityFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.chat, action: \.chat) {
            ChatFeature()
        }
        Scope(state: \.more, action: \.more) {
            MoreFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                let keychainClient = keychainClient
                let userDefaultsClient = userDefaultsClient
                let reissueTokenUseCase = reissueTokenUseCase
                var effects: [Effect<Action>] = [
                    .run { send in
                        for await _ in NotificationCenter.default.notifications(named: .authSessionExpired) {
                            await send(.authSessionExpired)
                        }
                    }
                    .cancellable(
                        id: "RootFeature.authSessionObserver",
                        cancelInFlight: true
                    )
                ]
                
                if state.authInfo == nil, state.isAuthLoading {
                    effects.append(
                        .run { send in
                            let hasLaunchedBefore = try userDefaultsClient.load(for: .hasLaunchedBefore) ?? false

                            if !hasLaunchedBefore {
                                try keychainClient.delete(for: .auth)
                                try userDefaultsClient.save(true, for: .hasLaunchedBefore)
                            }

                            let auth = try keychainClient.load(for: .auth)
                            let pendingOnboardingUserTypeRawValue = try userDefaultsClient.load(for: .pendingOnboardingUserType)
                            let pendingOnboardingUserType = pendingOnboardingUserTypeRawValue.flatMap(OnboardingUserType.init(rawValue:))
                            let resolvedAuth = await Self.resolveStoredAuth(
                                auth,
                                keychainClient: keychainClient,
                                reissueToken: reissueTokenUseCase.execute
                            )
                            await send(.storedAuthLoaded(resolvedAuth, pendingOnboardingUserType))
                        } catch: { _, send in
                            await send(.storedAuthLoaded(nil, nil))
                        }
                    )
                }
                
                return .merge(effects)
                
            case let .storedAuthLoaded(auth, pendingOnboardingUserType):
                state.authInfo = auth
                state.isAuthLoading = false

                guard auth?.onboardingRequired == true else {
                    userDefaultsClient.delete(for: .pendingOnboardingUserType)
                    return .none
                }

                if let pendingOnboardingUserType {
                    state.onboarding = OnboardingFeature.State(userType: pendingOnboardingUserType)
                } else {
                    state.authInfo = nil
                    state.login.authInfo = auth
                    state.login.currentSheet = .userTypeSelect
                }

                return .none

            case .authSessionExpired:
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                state = State(isAuthLoading: false)
                return .cancel(id: "RootFeature.fetchCurrentUser")

            case .mainTabAppeared:
                return fetchCurrentUserIfNeeded(state: &state)

            case let .currentUserResponse(.success(user)):
                guard state.authInfo?.onboardingRequired == false else {
                    state.isCurrentUserLoading = false
                    return .none
                }

                state.isCurrentUserLoading = false
                return .send(.more(.userProfileUpdated(user)))

            case .currentUserResponse(.failure):
                state.isCurrentUserLoading = false
                return .none

            case let .login(.loginSuccess(auth)):
                guard !auth.onboardingRequired else { return .none }
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                state.authInfo = auth
                return .none
                
            case let .login(.userTypeSelected(userType)):
                guard state.login.isRequiredTermsAgreed,
                      let authInfo = state.login.authInfo else { return .none }
                try? userDefaultsClient.save(userType.rawValue, for: .pendingOnboardingUserType)
                state.authInfo = authInfo
                state.onboarding = OnboardingFeature.State(userType: userType)
                return .none
                
            case let .onboarding(.onboardingResponse(.success(auth))):
                let keychainClient = keychainClient
                
                return .run { send in
                    try keychainClient.save(auth, for: .auth)
                    await send(.saveAuthResponse(.success(auth)))
                } catch: { error, send in
                    await send(.saveAuthResponse(.failure(error)))
                }
            
            case let .saveAuthResponse(.success(updatedAuthInfo)):
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                state.authInfo = updatedAuthInfo
                return .none

            case .saveAuthResponse(.failure):
                return .none

            case let .home(.mapTabRequested(diagnosisID)):
                state.home.path.removeAll()
                return openMap(diagnosisID: diagnosisID, state: &state)

            case let .home(.mapPlaceSearchRequested(placeResult)):
                state.home.path.removeAll()
                state.selectedTab = .map
                return .send(.map(.placeSearchResultSelected(placeResult)))

            case let .home(.mapCoordinateRequested(coordinate)):
                state.home.path.removeAll()
                return openMap(coordinate: coordinate, state: &state)

            case .home(.chatTabRequested):
                state.home.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .home(.path(.element(id: _, action: .search(.popupRequested(popup))))):
                state.popup = popup
                return .none

            case let .home(.favoriteStatusResponse(listingID, .success(status))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.home.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: _, action: .savedListings(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .home(.path(.element(id: _, action: .recentlyViewedList(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none
                
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case let .popupPresented(popup):
                state.popup = popup
                return .none

            case .popupNoticeConfirmButtonTapped:
                state.popup = nil
                return .none

            case .popupActionPrimaryButtonTapped:
                guard case let .action(popup) = state.popup else { return .none }
                state.popup = nil
                guard let route = popup.primaryRoute else { return .none }
                return handlePopupRoute(route)

            case .popupActionSecondaryButtonTapped:
                guard case let .action(popup) = state.popup else { return .none }
                state.popup = nil
                guard let route = popup.secondaryRoute else { return .none }
                return handlePopupRoute(route)

            case let .map(.path(.element(id: _, action: .chatBot(.mapTabRequested(diagnosisID))))):
                state.map.path.removeAll()
                return openMap(diagnosisID: diagnosisID, state: &state)

            case .map(.path(.element(id: _, action: .listingApplication(.delegate(.chatTabRequested))))):
                state.map.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .map(.path(.element(id: _, action: .search(.popupRequested(popup))))):
                state.popup = popup
                return .none

            case let .map(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.map.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .chat(.mapTabRequested(diagnosisID)):
                state.chat.path.removeAll()
                return openMap(diagnosisID: diagnosisID, state: &state)

            case let .more(.popupRequested(popup)):
                state.popup = popup
                return .none

            case let .more(.mapCoordinateRequested(coordinate)):
                state.more.path.removeAll()
                return openMap(coordinate: coordinate, state: &state)

            case .more(.chatTabRequested):
                state.more.path.removeAll()
                state.selectedTab = .chat
                return .none

            case let .more(.path(.element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))))):
                guard let listingID = state.more.path[id: id, case: \.listingDetail]?.listingID else { return .none }
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.path(.element(id: _, action: .savedListings(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.path(.element(id: _, action: .recentlyViewedList(.favoriteStatusResponse(listingID, .success(status)))))):
                synchronizeFavoriteStatus(status, for: listingID, state: &state)
                return .none

            case let .more(.userProfileUpdated(userProfile)):
                state.currentUser = userProfile
                state.home.userType = userProfile.userType
                state.map.userType = userProfile.userType
                let didUpdateChatRole = state.chat.applyUserType(userProfile.userType)
                var effects: [Effect<Action>] = [
                    .send(.home(.onAppear))
                ]

                if didUpdateChatRole, state.selectedTab == .chat {
                    effects.append(.send(.chat(.onAppear)))
                }

                return .merge(effects)

            case .more(.logoutConfirmed):
                userDefaultsClient.delete(for: .mapDiagnosisButtonLastExpandedAt)
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                state = State(isAuthLoading: false)

                let logoutUseCase = logoutUseCase
                let keychainClient = keychainClient

                return .merge(
                    .cancel(id: "RootFeature.fetchCurrentUser"),
                    .run { _ in
                        defer {
                            try? keychainClient.delete(for: .auth)
                        }

                        do {
                            try await logoutUseCase.execute()
                        } catch {}
                    }
                )

            case .more(.deleteAccountConfirmed):
                userDefaultsClient.delete(for: .mapDiagnosisButtonLastExpandedAt)
                userDefaultsClient.delete(for: .pendingOnboardingUserType)
                state = State(isAuthLoading: false)

                let deleteCurrentUserUseCase = deleteCurrentUserUseCase
                let keychainClient = keychainClient

                return .merge(
                    .cancel(id: "RootFeature.fetchCurrentUser"),
                    .run { _ in
                        defer {
                            try? keychainClient.delete(for: .auth)
                        }

                        do {
                            try await deleteCurrentUserUseCase.execute()
                        } catch {}
                    }
                )
                
            case .login, .onboarding, .home, .community, .map, .chat, .more:
                return .none
            }
        }
    }

    private func fetchCurrentUserIfNeeded(state: inout State) -> Effect<Action> {
        guard state.authInfo?.onboardingRequired == false,
              state.currentUser == nil,
              !state.isCurrentUserLoading
        else {
            return .none
        }

        state.isCurrentUserLoading = true
        let fetchCurrentUserUseCase = fetchCurrentUserUseCase

        return .run { send in
            do {
                let user = try await fetchCurrentUserUseCase.execute()
                await send(.currentUserResponse(.success(user)))
            } catch {
                await send(.currentUserResponse(.failure(error)))
            }
        }
        .cancellable(
            id: "RootFeature.fetchCurrentUser",
            cancelInFlight: true
        )
    }

}
