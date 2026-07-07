//
//  HomeFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @Dependency(\.listingClient)
    var listingClient

    @Reducer
    enum Path {
        case savedListings(SavedListingsFeature)
        case recentlyViewedList(RecentlyViewedFeature)
        case notifications(NotificationsFeature)
        case chatBot(ChatBotFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var recentlyViewedItems: [ListingItemModel] = []
        var isRecentlyViewedLoading: Bool = false
        var favoriteUpdatingIDs: Set<String> = []
        var recentlyViewedErrorMessage: String?
        var quiz: QuizModel
        var livingGuides: [LivingGuide] = []
        
        init(
            recentlyViewedItems: [ListingItemModel] = [],
            quiz: Quiz = Quiz.mockQuiz,
            livingGuides: [LivingGuide] = LivingGuide.mockLivingGuide
        ) {
            self.recentlyViewedItems = recentlyViewedItems
            self.quiz = QuizModel(entity: quiz, selectedAnswerIndex: nil)
            self.livingGuides = livingGuides
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case path(StackActionOf<Path>)
        case mapTabRequested(diagnosisID: String?)
        case onAppear
        case recentListingsResponse(Result<[Listing], DataError>)
        
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
        case livingGuideItemTapped(id: Int)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isRecentlyViewedLoading else { return .none }
                state.isRecentlyViewedLoading = true
                state.recentlyViewedErrorMessage = nil

                return .run { [listingClient] send in
                    do {
                        let listings = try await listingClient.fetchRecentListings()
                        await send(.recentListingsResponse(.success(listings)))
                    } catch {
                        await send(.recentListingsResponse(.failure(.from(error))))
                    }
                }

            case let .recentListingsResponse(.success(listings)):
                state.recentlyViewedItems = listings.map(ListingItemModel.init(listing:))
                state.isRecentlyViewedLoading = false
                state.recentlyViewedErrorMessage = nil
                return .none

            case let .recentListingsResponse(.failure(error)):
                state.isRecentlyViewedLoading = false
                state.recentlyViewedErrorMessage = error.localizedDescription
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

            case let .path(.element(id: _, action: .chatBot(.mapTabRequested(diagnosisID)))):
                return .send(.mapTabRequested(diagnosisID: diagnosisID))
                
            case .path:
                return .none
                
            case .navigationSearchTapped:
                // TODO: 검색으로 네비게이션
                return .none
                
            case .navigationHeartTapped:
                state.path.append(.savedListings(SavedListingsFeature.State()))
                return .none
                
            case .navigationNoticeTapped:
                state.path.append(.notifications(NotificationsFeature.State()))
                return .none
                
            case .roomFinderBannerTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none
                
            case .seeAllListingsTapped:
                state.path.append(.recentlyViewedList(RecentlyViewedFeature.State()))
                return .none
                
            case .browseListingsTapped:
                return .send(.mapTabRequested(diagnosisID: nil))
                
            case let .cardTapped(id):
                // TODO: 매물 상세 뷰 네비게이션 (지도)
                print("선택 매물 \(id)")
                return .none
                
            case let .likeButtonTapped(id):
                guard let item = state.recentlyViewedItems.first(where: { $0.id == id }),
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
                
            case let .quizOptionTapped(index):
                guard !state.quiz.hasAnswered else { return .none }
                state.quiz.selectedAnswerIndex = index
                return .none
                
            case let .livingGuideItemTapped(id):
                print("선택 콘텐츠 \(id)")
                return .none

            case .mapTabRequested:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension HomeFeature.Path.State: Equatable {}
