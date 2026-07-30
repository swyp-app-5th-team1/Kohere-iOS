import ComposableArchitecture

extension RootFeature {
    @ObservableState
    struct State: Equatable {
        var authInfo: Auth?
        var currentUser: UserProfile?
        var appLanguage: AppLanguage = .systemDefault
        var isAuthLoading = true
        var isSplashMinimumDurationElapsed = false
        var isCurrentUserLoading = false
        var isLogoutRequesting = false
        var isDeleteAccountRequesting = false
        var isAuthenticationFlowPresented = false
        var login = LoginFeature.State()
        var onboarding = OnboardingFeature.State()
        var selectedTab: AppTab = .home
        var popup: AppPopup?
        var home = HomeFeature.State()
        var community = CommunityFeature.State()
        var map = MapFeature.State()
        var chat = ChatFeature.State()
        var more = MoreFeature.State()

        var isSplashPresented: Bool { isAuthLoading || !isSplashMinimumDurationElapsed }
    }
}
