//
//  HomeFeature.swift
//  Kohere
//
//  Created by soomin on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient

    @Reducer
    enum Path {
        case savedListings(SavedListingsFeature)
        case recentlyViewedList(RecentlyViewedFeature)
        case listingDetail(ListingDetailFeature)
        case listingApplication(ListingApplicationFeature)
        case listingApplicationPrivacyWeb(ListingApplicationPrivacyWebFeature)
        case notifications(NotificationsFeature)
        case chatBot(ChatBotFeature)
        case livingGuideDetail(LivingGuideDetailFeature)
        case search(SearchFeature)
    }

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var recentlyViewedSection: HomeRecentlyViewedFeature.State
        var quizSection: HomeQuizFeature.State
        var livingGuideSection: HomeLivingGuideFeature.State
        
        init(
            userType: UserType? = nil,
            appLanguage: AppLanguage = .english,
            recentlyViewedItems: [ListingItemModel] = [],
            quiz: Quiz = Quiz.mockQuiz,
            livingGuides: [LivingGuide] = []
        ) {
            self.recentlyViewedSection = HomeRecentlyViewedFeature.State(
                userType: userType,
                appLanguage: appLanguage,
                items: recentlyViewedItems
            )
            self.quizSection = HomeQuizFeature.State(quiz: quiz)
            self.livingGuideSection = HomeLivingGuideFeature.State(guides: livingGuides)
        }
    }
    
    // MARK: - Action

    @CasePathable
    enum Delegate {
        case authenticationRequired
        case mapRequested(MapEntryRequest)
        case mapPlaceSearchRequested(SearchPlaceResult)
        case listingMapPreviewRequested(MapCoordinate)
        case chatRoomRequested(listingID: String)
        case popupRequested(AppPopup)
        case favoriteStatusChanged(listingID: String, status: ListingFavoriteStatus)
    }

    enum Action {
        case path(StackActionOf<Path>)
        case delegate(Delegate)
        case onAppear
        case cancelEffects
        case recentlyViewedSection(HomeRecentlyViewedFeature.Action)
        case quizSection(HomeQuizFeature.Action)
        case livingGuideSection(HomeLivingGuideFeature.Action)
        
        case navigationSearchTapped
        case navigationHeartTapped
        case navigationNoticeTapped
        
        case roomFinderBannerTapped
        case seeAllListingsTapped
        case browseListingsTapped
        case cardTapped(id: String)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.recentlyViewedSection, action: \.recentlyViewedSection) {
            HomeRecentlyViewedFeature()
        }
        Scope(state: \.quizSection, action: \.quizSection) {
            HomeQuizFeature()
        }
        Scope(state: \.livingGuideSection, action: \.livingGuideSection) {
            HomeLivingGuideFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.recentlyViewedSection(.onAppear)),
                    .send(.quizSection(.onAppear)),
                    .send(.livingGuideSection(.onAppear))
                )

            case .cancelEffects:
                return .merge(
                    .send(.recentlyViewedSection(.cancelEffects)),
                    .send(.quizSection(.cancelEffects)),
                    .send(.livingGuideSection(.cancelEffects))
                )

            case let .path(pathAction):
                return handlePathAction(pathAction, state: &state)
                
            case .navigationSearchTapped:
                state.path.append(.search(SearchFeature.initialState(userDefaultsClient: userDefaultsClient, appLanguage: state.appLanguage)))
                return .none
                
            case .navigationHeartTapped:
                guard state.userType != nil else {
                    return .send(.delegate(.authenticationRequired))
                }
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(
                    .savedListings(
                        SavedListingsFeature.State(userType: state.userType, appLanguage: state.appLanguage,
                                                   krwToUSDExchangeRate: state.krwToUSDExchangeRate)
                    )
                )
                return .none
                
            case .navigationNoticeTapped:
                guard state.userType != nil else {
                    return .send(.delegate(.authenticationRequired))
                }
                state.path.append(.notifications(NotificationsFeature.State()))
                return .none
                
            case .roomFinderBannerTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none
                
            case .seeAllListingsTapped:
                guard state.userType != nil else {
                    return .send(.delegate(.authenticationRequired))
                }
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(
                    .recentlyViewedList(
                        RecentlyViewedFeature.State(userType: state.userType, appLanguage: state.appLanguage,
                                                    krwToUSDExchangeRate: state.krwToUSDExchangeRate)
                    )
                )
                return .none
                
            case .browseListingsTapped:
                return .send(.delegate(.mapRequested(.browseListings)))
                
            case let .cardTapped(id):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(listingID: id, userType: state.userType, appLanguage: state.appLanguage)
                    )
                )
                return .none
                
            case let .livingGuideSection(.itemTapped(id)):
                guard let guide = state.livingGuideSection.guides.first(where: { $0.id == id }) else {
                    return .none
                }
                state.path.append(.livingGuideDetail(LivingGuideDetailFeature.State(guide: guide)))
                return .none

            case .recentlyViewedSection(.likeButtonTapped) where state.userType == nil:
                return .send(.delegate(.authenticationRequired))

            case let .recentlyViewedSection(.favoriteStatusResponse(listingID, .success(status))):
                return .send(.delegate(.favoriteStatusChanged(listingID: listingID, status: status)))

            case .recentlyViewedSection, .quizSection, .livingGuideSection:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension HomeFeature.Path.State: Equatable {}

extension HomeFeature.State {
    mutating func synchronizeFavoriteStatus(_ status: ListingFavoriteStatus, for listingID: String) {
        recentlyViewedSection.synchronizeFavoriteStatus(status, for: listingID)
    }

    var canUseFavoriteFeatures: Bool {
        recentlyViewedSection.canUseFavoriteFeatures
    }

    var showsFavoriteControls: Bool {
        userType != .landlord
    }

    var userType: UserType? {
        get { recentlyViewedSection.userType }
        set { recentlyViewedSection.userType = newValue }
    }

    var appLanguage: AppLanguage {
        get { recentlyViewedSection.appLanguage }
        set { recentlyViewedSection.appLanguage = newValue }
    }

    var krwToUSDExchangeRate: KRWToUSDExchangeRate? {
        get { recentlyViewedSection.exchangeRate }
        set { recentlyViewedSection.exchangeRate = newValue }
    }

}
