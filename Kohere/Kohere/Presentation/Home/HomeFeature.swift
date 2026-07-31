//
//  HomeFeature.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
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
        var recentlyViewed: HomeRecentlyViewedFeature.State
        var quizSection: HomeQuizFeature.State
        var livingGuide: HomeLivingGuideFeature.State
        
        init(
            userType: UserType? = nil,
            appLanguage: AppLanguage = .systemDefault,
            recentlyViewedItems: [ListingItemModel] = [],
            quiz: Quiz = Quiz.mockQuiz,
            livingGuides: [LivingGuide] = []
        ) {
            self.recentlyViewed = HomeRecentlyViewedFeature.State(userType: userType, appLanguage: appLanguage, items: recentlyViewedItems)
            self.quizSection = HomeQuizFeature.State(quiz: quiz)
            self.livingGuide = HomeLivingGuideFeature.State(guides: livingGuides)
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case path(StackActionOf<Path>)
        case mapRequested(MapEntryRequest)
        case mapPlaceSearchRequested(SearchPlaceResult)
        case listingMapPreviewRequested(MapCoordinate)
        case chatTabRequested
        case onAppear
        case cancelEffects
        case recentlyViewed(HomeRecentlyViewedFeature.Action)
        case quiz(HomeQuizFeature.Action)
        case livingGuide(HomeLivingGuideFeature.Action)
        
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
        Scope(state: \.recentlyViewed, action: \.recentlyViewed) {
            HomeRecentlyViewedFeature()
        }
        Scope(state: \.quizSection, action: \.quiz) {
            HomeQuizFeature()
        }
        Scope(state: \.livingGuide, action: \.livingGuide) {
            HomeLivingGuideFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .concatenate(
                    .send(.recentlyViewed(.onAppear)),
                    .send(.quiz(.onAppear)),
                    .send(.livingGuide(.onAppear))
                )

            case .cancelEffects:
                return .concatenate(
                    .send(.recentlyViewed(.cancelEffects)),
                    .send(.quiz(.cancelEffects)),
                    .send(.livingGuide(.cancelEffects))
                )

            case let .path(pathAction):
                return handlePathAction(pathAction, state: &state)
                
            case .navigationSearchTapped:
                state.path.append(.search(SearchFeature.initialState(
                    userDefaultsClient: userDefaultsClient,
                    appLanguage: state.appLanguage
                )))
                return .none
                
            case .navigationHeartTapped:
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(
                    .savedListings(
                        SavedListingsFeature.State(
                            userType: state.userType,
                            appLanguage: state.appLanguage,
                            krwToUSDExchangeRate: state.krwToUSDExchangeRate
                        )
                    )
                )
                return .none
                
            case .navigationNoticeTapped:
                state.path.append(.notifications(NotificationsFeature.State()))
                return .none
                
            case .roomFinderBannerTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none
                
            case .seeAllListingsTapped:
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(
                    .recentlyViewedList(
                        RecentlyViewedFeature.State(userType: state.userType, appLanguage: state.appLanguage, krwToUSDExchangeRate: state.krwToUSDExchangeRate)
                    )
                )
                return .none
                
            case .browseListingsTapped:
                return .send(.mapRequested(.browseListings))
                
            case let .cardTapped(id):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: id,
                            userType: state.userType,
                            appLanguage: state.appLanguage
                        )
                    )
                )
                return .none
                
            case let .livingGuide(.itemTapped(id)):
                guard state.canShowLivingContent,
                      let guide = state.livingGuides.first(where: { $0.id == id }) else {
                    return .none
                }
                state.path.append(.livingGuideDetail(LivingGuideDetailFeature.State(guide: guide)))
                return .none

            case .recentlyViewed, .quiz, .livingGuide:
                return .none

            case .mapRequested, .mapPlaceSearchRequested, .listingMapPreviewRequested, .chatTabRequested:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension HomeFeature.Path.State: Equatable {}

extension HomeFeature.State {
    mutating func synchronizeFavoriteStatus(_ status: ListingFavoriteStatus, for listingID: String) {
        recentlyViewed.synchronizeFavoriteStatus(status, for: listingID)
    }

    var canUseFavoriteFeatures: Bool {
        recentlyViewed.canUseFavoriteFeatures
    }

    var showsFavoriteControls: Bool {
        userType != .landlord
    }

    var canShowLivingContent: Bool {
        true
    }

    var userType: UserType? {
        get { recentlyViewed.userType }
        set { recentlyViewed.userType = newValue }
    }

    var appLanguage: AppLanguage {
        get { recentlyViewed.appLanguage }
        set { recentlyViewed.appLanguage = newValue }
    }

    var recentListings: [Listing] {
        get { recentlyViewed.recentListings }
        set { recentlyViewed.recentListings = newValue }
    }

    var recentlyViewedItems: [ListingItemModel] {
        get { recentlyViewed.items }
        set { recentlyViewed.items = newValue }
    }

    var isRecentlyViewedLoading: Bool {
        get { recentlyViewed.isLoading }
        set { recentlyViewed.isLoading = newValue }
    }

    var isRecentlyViewedLoaded: Bool {
        get { recentlyViewed.isLoaded }
        set { recentlyViewed.isLoaded = newValue }
    }

    var favoriteUpdatingIDs: Set<String> {
        get { recentlyViewed.favoriteUpdatingIDs }
        set { recentlyViewed.favoriteUpdatingIDs = newValue }
    }

    var recentlyViewedErrorMessage: String? {
        get { recentlyViewed.errorMessage }
        set { recentlyViewed.errorMessage = newValue }
    }

    var krwToUSDExchangeRate: KRWToUSDExchangeRate? {
        get { recentlyViewed.exchangeRate }
        set { recentlyViewed.exchangeRate = newValue }
    }

    var isExchangeRateLoading: Bool {
        get { recentlyViewed.isExchangeRateLoading }
        set { recentlyViewed.isExchangeRateLoading = newValue }
    }

    var quiz: QuizModel {
        get { quizSection.quiz }
        set { quizSection.quiz = newValue }
    }

    var isQuizLoading: Bool {
        get { quizSection.isLoading }
        set { quizSection.isLoading = newValue }
    }

    var isQuizLoaded: Bool {
        get { quizSection.isLoaded }
        set { quizSection.isLoaded = newValue }
    }

    var isQuizAnswerSubmitting: Bool {
        get { quizSection.isAnswerSubmitting }
        set { quizSection.isAnswerSubmitting = newValue }
    }

    var quizErrorMessage: String? {
        get { quizSection.errorMessage }
        set { quizSection.errorMessage = newValue }
    }

    var livingGuides: [LivingGuide] {
        get { livingGuide.guides }
        set { livingGuide.guides = newValue }
    }

    var isLivingGuidesLoading: Bool {
        get { livingGuide.isLoading }
        set { livingGuide.isLoading = newValue }
    }

    var isLivingGuidesLoaded: Bool {
        get { livingGuide.isLoaded }
        set { livingGuide.isLoaded = newValue }
    }

    var livingGuidesErrorMessage: String? {
        get { livingGuide.errorMessage }
        set { livingGuide.errorMessage = newValue }
    }
}
