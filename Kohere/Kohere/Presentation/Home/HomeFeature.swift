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
    @Dependency(\.listingClient)
    var listingClient
    @Dependency(\.quizClient)
    var quizClient
    @Dependency(\.lifeTipClient)
    var lifeTipClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient
    @Dependency(\.fetchKRWToUSDExchangeRateUseCase)
    var fetchKRWToUSDExchangeRateUseCase
    @Dependency(\.convertMonthlyRentCurrencyUseCase)
    var convertMonthlyRentCurrencyUseCase

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
        var userType: UserType?
        var appLanguage: AppLanguage
        var recentListings: [Listing] = []
        var recentlyViewedItems: [ListingItemModel] = []
        var isRecentlyViewedLoading: Bool = false
        var isRecentlyViewedLoaded: Bool = false
        var favoriteUpdatingIDs: Set<String> = []
        var recentlyViewedErrorMessage: String?
        var krwToUSDExchangeRate: KRWToUSDExchangeRate?
        var isExchangeRateLoading: Bool = false
        var quiz: QuizModel
        var isQuizLoading: Bool = false
        var isQuizLoaded: Bool = false
        var isQuizAnswerSubmitting: Bool = false
        var quizErrorMessage: String?
        var livingGuides: [LivingGuide] = []
        var isLivingGuidesLoading: Bool = false
        var isLivingGuidesLoaded: Bool = false
        var livingGuidesErrorMessage: String?
        
        init(
            userType: UserType? = nil,
            appLanguage: AppLanguage = .systemDefault,
            recentlyViewedItems: [ListingItemModel] = [],
            quiz: Quiz = Quiz.mockQuiz,
            livingGuides: [LivingGuide] = []
        ) {
            self.userType = userType
            self.appLanguage = appLanguage
            self.recentlyViewedItems = recentlyViewedItems
            self.isRecentlyViewedLoaded = !recentlyViewedItems.isEmpty
            self.quiz = QuizModel(entity: quiz, selectedChoiceKey: nil)
            self.livingGuides = livingGuides
            self.isLivingGuidesLoaded = !livingGuides.isEmpty
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
        case recentListingsResponse(Result<[Listing], DataError>)
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, Error>)
        case randomQuizResponse(Result<Quiz, DataError>)
        case lifeTipTopicsResponse(Result<[LivingGuide], DataError>)
        
        case navigationSearchTapped
        case navigationHeartTapped
        case navigationNoticeTapped
        
        case roomFinderBannerTapped
        case seeAllListingsTapped
        case browseListingsTapped
        case cardTapped(id: String)
        case likeButtonTapped(id: String)
        case favoriteStatusResponse(listingID: String, Result<ListingFavoriteStatus, DataError>)
        
        case quizOptionTapped(index: Int)
        case quizAnswerResponse(Result<QuizAnswerResult, DataError>)
        case livingGuideItemTapped(id: Int)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                var effects: [Effect<Action>] = []

                if !state.isRecentlyViewedLoading && !state.isRecentlyViewedLoaded {
                    state.isRecentlyViewedLoading = true
                    state.recentlyViewedErrorMessage = nil

                    effects.append(.run { [listingClient] send in
                        do {
                            let listings = try await listingClient.fetchRecentListings()
                            await send(.recentListingsResponse(.success(listings)))
                        } catch {
                            await send(.recentListingsResponse(.failure(.from(error))))
                        }
                    })
                }

                if state.krwToUSDExchangeRate == nil && !state.isExchangeRateLoading {
                    state.isExchangeRateLoading = true

                    effects.append(.run { [fetchKRWToUSDExchangeRateUseCase] send in
                        do {
                            let exchangeRate = try await fetchKRWToUSDExchangeRateUseCase.execute()
                            await send(.exchangeRateResponse(.success(exchangeRate)))
                        } catch {
                            await send(.exchangeRateResponse(.failure(error)))
                        }
                    })
                }

                if state.canShowTenantLivingContent,
                   !state.isQuizLoading,
                   !state.isQuizLoaded {
                    state.isQuizLoading = true
                    state.quizErrorMessage = nil

                    effects.append(.run { [quizClient] send in
                        do {
                            let quiz = try await quizClient.fetchRandomQuiz()
                            await send(.randomQuizResponse(.success(quiz)))
                        } catch {
                            let dataError = DataError.from(error)
                            print("[HomeFeature] random quiz failed. error=\(dataError.debugDescription)")
                            await send(.randomQuizResponse(.failure(dataError)))
                        }
                    })
                }

                if state.canShowTenantLivingContent,
                   !state.isLivingGuidesLoading,
                   !state.isLivingGuidesLoaded {
                    state.isLivingGuidesLoading = true
                    state.livingGuidesErrorMessage = nil

                    effects.append(.run { [lifeTipClient] send in
                        do {
                            let topics = try await lifeTipClient.fetchTopics()
                            await send(.lifeTipTopicsResponse(.success(topics)))
                        } catch {
                            await send(.lifeTipTopicsResponse(.failure(.from(error))))
                        }
                    })
                }

                return .merge(effects)
                
            case let .randomQuizResponse(.success(quiz)):
                state.quiz = QuizModel(entity: quiz)
                state.isQuizLoading = false
                state.isQuizLoaded = true
                state.quizErrorMessage = nil
                return .none

            case let .randomQuizResponse(.failure(error)):
                state.isQuizLoading = false
                state.quizErrorMessage = error.localizedDescription
                return .none

            case let .quizOptionTapped(index):
                guard state.canShowTenantLivingContent,
                      state.isQuizLoaded,
                      !state.quiz.hasAnswered,
                      !state.isQuizAnswerSubmitting,
                      let selectedChoiceKey = state.quiz.choiceKey(for: index)
                else { return .none }

                state.quiz.selectedChoiceKey = selectedChoiceKey
                state.isQuizAnswerSubmitting = true
                state.quizErrorMessage = nil

                return .run { [quizClient, quizID = state.quiz.id] send in
                    do {
                        let result = try await quizClient.submitAnswer(quizID, selectedChoiceKey)
                        await send(.quizAnswerResponse(.success(result)))
                    } catch {
                        let dataError = DataError.from(error)
                        print("[HomeFeature] quiz answer failed. quizID=\(quizID), selectedChoice=\(selectedChoiceKey), error=\(dataError.debugDescription)")
                        await send(.quizAnswerResponse(.failure(dataError)))
                    }
                }

            case let .quizAnswerResponse(.success(result)):
                state.quiz.apply(answerResult: result)
                state.isQuizAnswerSubmitting = false
                state.quizErrorMessage = nil
                return .none

            case let .quizAnswerResponse(.failure(error)):
                state.quiz.selectedChoiceKey = nil
                state.isQuizAnswerSubmitting = false
                state.quizErrorMessage = error.localizedDescription
                return .none

            case let .recentListingsResponse(.success(listings)):
                state.recentListings = listings
                state.recentlyViewedItems = listings.map {
                    ListingItemModel(
                        listing: $0,
                        exchangeRate: state.krwToUSDExchangeRate,
                        convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
                        language: state.appLanguage
                    )
                }
                state.isRecentlyViewedLoading = false
                state.isRecentlyViewedLoaded = true
                state.recentlyViewedErrorMessage = nil
                return .none

            case let .recentListingsResponse(.failure(error)):
                state.isRecentlyViewedLoading = false
                state.isRecentlyViewedLoaded = false
                state.recentlyViewedErrorMessage = error.localizedDescription
                return .none

            case let .exchangeRateResponse(.success(exchangeRate)):
                state.krwToUSDExchangeRate = exchangeRate
                state.isExchangeRateLoading = false

                guard !state.recentListings.isEmpty else { return .none }

                let currentItems = state.recentlyViewedItems
                state.recentlyViewedItems = state.recentListings.map { listing in
                    var item = ListingItemModel(
                        listing: listing,
                        exchangeRate: exchangeRate,
                        convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
                        language: state.appLanguage
                    )

                    if let currentItem = currentItems.first(where: { $0.id == item.id }) {
                        item.isLiked = currentItem.isLiked
                        item.favoriteCount = currentItem.favoriteCount
                    }

                    return item
                }
                return .none

            case .exchangeRateResponse(.failure):
                state.isExchangeRateLoading = false
                return .none

            case let .lifeTipTopicsResponse(.success(guides)):
                state.isLivingGuidesLoading = false
                state.isLivingGuidesLoaded = true
                state.livingGuidesErrorMessage = nil
                state.livingGuides = guides
                return .none

            case let .lifeTipTopicsResponse(.failure(error)):
                state.isLivingGuidesLoading = false
                state.isLivingGuidesLoaded = false
                state.livingGuidesErrorMessage = error.localizedDescription
                return .none

            case let .path(pathAction):
                return handlePathAction(pathAction, state: &state)
                
            case .navigationSearchTapped:
                state.path.append(.search(SearchFeature.initialState(userDefaultsClient: userDefaultsClient)))
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
                state.path.append(
                    .recentlyViewedList(
                        RecentlyViewedFeature.State(
                            userType: state.userType,
                            appLanguage: state.appLanguage,
                            krwToUSDExchangeRate: state.krwToUSDExchangeRate
                        )
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
                
            case let .likeButtonTapped(id):
                guard state.canUseFavoriteFeatures,
                      let item = state.recentlyViewedItems.first(where: { $0.id == id }),
                      !state.favoriteUpdatingIDs.contains(id)
                else { return .none }

                state.favoriteUpdatingIDs.insert(id)
                state.recentlyViewedErrorMessage = nil

                return .run { [listingClient, isLiked = item.isLiked] send in
                    do {
                        let status: ListingFavoriteStatus
                        if isLiked {
                            status = try await listingClient.removeFavorite(id)
                        } else {
                            status = try await listingClient.addFavorite(id)
                        }
                        await send(.favoriteStatusResponse(listingID: id, .success(status)))
                    } catch {
                        await send(.favoriteStatusResponse(listingID: id, .failure(.from(error))))
                    }
                }

            case let .favoriteStatusResponse(listingID, .success(status)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.recentlyViewedErrorMessage = nil
                state.synchronizeFavoriteStatus(status, for: listingID)
                return .none

            case let .favoriteStatusResponse(listingID, .failure(error)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.recentlyViewedErrorMessage = error.localizedDescription
                return .none
                
            case let .livingGuideItemTapped(id):
                guard state.canShowTenantLivingContent,
                      let guide = state.livingGuides.first(where: { $0.id == id }) else {
                    return .none
                }
                state.path.append(.livingGuideDetail(LivingGuideDetailFeature.State(guide: guide)))
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
    mutating func synchronizeFavoriteStatus(
        _ status: ListingFavoriteStatus,
        for listingID: String
    ) {
        guard let index = recentlyViewedItems.firstIndex(where: { $0.id == listingID }) else { return }
        recentlyViewedItems[index].isLiked = status.isFavorited
        recentlyViewedItems[index].favoriteCount = status.favoriteCount
    }

    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }

    var canShowTenantLivingContent: Bool {
        userType == .tenant
    }
}
