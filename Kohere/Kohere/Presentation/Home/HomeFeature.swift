//
//  HomeFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture

@Reducer
struct HomeFeature {
    @Reducer
    enum Path {
        case savedListings(SavedListingsFeature)
        case recentlyViewedList(RecentlyViewedFeature)
        case notifications(NotificationsFeature)
        case chatBot(ChatBotFeature)
        case search(SearchFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var recentlyViewedItems: [ListingItemModel] = []
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
        
        case navigationSearchTapped
        case navigationHeartTapped
        case navigationNoticeTapped
        
        case roomFinderBannerTapped
        case seeAllListingsTapped
        case browseListingsTapped
        case cardTapped(id: String)
        case likeButtonTapped(id: String)
        
        case quizOptionTapped(index: Int)
        case livingGuideItemTapped(id: Int)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
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

            case .path(.element(id: _, action: .search(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .chatBot(.mapTabRequested(diagnosisID)))):
                return .send(.mapTabRequested(diagnosisID: diagnosisID))
                
            case .path:
                return .none
                
            case .navigationSearchTapped:
                state.path.append(.search(SearchFeature.State()))
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
                if let index = state.recentlyViewedItems.firstIndex(where: { $0.id == id }) {
                    state.recentlyViewedItems[index].isLiked.toggle()
                }
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
