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

    @Reducer
    enum Path {
        case savedListings(SavedListingsFeature)
        case recentlyViewedList(RecentlyViewedFeature)
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
        var recentlyViewedItems: [ListingItemModel] = []
        var isRecentlyViewedLoading: Bool = false
        var isRecentlyViewedLoaded: Bool = false
        var favoriteUpdatingIDs: Set<String> = []
        var recentlyViewedErrorMessage: String?
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
            recentlyViewedItems: [ListingItemModel] = [],
            quiz: Quiz = Quiz.mockQuiz,
            livingGuides: [LivingGuide] = []
        ) {
            self.userType = userType
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
        case mapTabRequested(diagnosisID: String?)
        case mapPlaceSearchRequested(SearchPlaceResult)
        case onAppear
        case recentListingsResponse(Result<[Listing], DataError>)
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

                if !state.isQuizLoading && !state.isQuizLoaded {
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

                if !state.isLivingGuidesLoading && !state.isLivingGuidesLoaded {
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
                guard state.isQuizLoaded,
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
                state.recentlyViewedItems = listings.map(ListingItemModel.init(listing:))
                state.isRecentlyViewedLoading = false
                state.isRecentlyViewedLoaded = true
                state.recentlyViewedErrorMessage = nil
                return .none

            case let .recentListingsResponse(.failure(error)):
                state.isRecentlyViewedLoading = false
                state.isRecentlyViewedLoaded = false
                state.recentlyViewedErrorMessage = error.localizedDescription
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

            case .path(.element(id: _, action: .savedListings(.backButtonTapped))):
                _ = state.path.popLast()
                return .none
                
            case .path(.element(id: _, action: .recentlyViewedList(.backButtonTapped))):
                _ = state.path.popLast()
                return .none
                
            case .path(.element(id: _, action: .notifications(.backButtonTapped))):
                _ = state.path.popLast()
                return .none
                
            case .path(.element(id: _, action: .chatBot(.backButtonTapped))):
                _ = state.path.popLast() 
                return .none

            case .path(.element(id: _, action: .livingGuideDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

			case .path(.element(id: _, action: .search(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .chatBot(.mapTabRequested(diagnosisID)))):
                return .send(.mapTabRequested(diagnosisID: diagnosisID))

            case .path(.element(id: _, action: .search(.bannerTapped))):
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none

            case let .path(.element(id: _, action: .search(.placeResultTapped(placeResult)))):
                state.path.removeAll()
                return .send(.mapPlaceSearchRequested(placeResult))
                
            case .path:
                return .none
                
            case .navigationSearchTapped:
                state.path.append(.search(SearchFeature.initialState(userDefaultsClient: userDefaultsClient)))
                return .none
                
            case .navigationHeartTapped:
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(.savedListings(SavedListingsFeature.State(userType: state.userType)))
                return .none
                
            case .navigationNoticeTapped:
                state.path.append(.notifications(NotificationsFeature.State()))
                return .none
                
            case .roomFinderBannerTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none
                
            case .seeAllListingsTapped:
                state.path.append(.recentlyViewedList(RecentlyViewedFeature.State(userType: state.userType)))
                return .none
                
            case .browseListingsTapped:
                return .send(.mapTabRequested(diagnosisID: nil))
                
            case let .cardTapped(id):
                // TODO: 매물 상세 뷰 네비게이션 (지도)
                print("선택 매물 \(id)")
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

                if let index = state.recentlyViewedItems.firstIndex(where: { $0.id == listingID }) {
                    state.recentlyViewedItems[index].isLiked = status.isFavorited
                    state.recentlyViewedItems[index].favoriteCount = status.favoriteCount
                }
                return .none

            case let .favoriteStatusResponse(listingID, .failure(error)):
                state.favoriteUpdatingIDs.remove(listingID)
                state.recentlyViewedErrorMessage = error.localizedDescription
                return .none
                
            case let .livingGuideItemTapped(id):
                guard let guide = state.livingGuides.first(where: { $0.id == id }) else {
                    return .none
                }
                state.path.append(.livingGuideDetail(LivingGuideDetailFeature.State(guide: guide)))
                return .none

            case .mapTabRequested, .mapPlaceSearchRequested:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension HomeFeature.Path.State: Equatable {}

extension HomeFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}
