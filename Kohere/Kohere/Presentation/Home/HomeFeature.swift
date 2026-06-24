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
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var recentlyViewedItems: [ListingItem] = []
        
        init(recentlyViewedItems: [ListingItem] = ListingItem.mockList) {
            self.recentlyViewedItems = recentlyViewedItems
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case path(StackActionOf<Path>)
        
        case navigationSearchTapped
        case navigationHeartTapped
        case navigationNoticeTapped
        
        case roomFinderBannerTapped
        case seeAllListingsTapped
        case browseListingsTapped
        case cardTapped(id: Int)
        case likeButtonTapped(id: Int)
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
                // TODO: 지도 탭으로 네비게이션
                return .none
                
            case .seeAllListingsTapped:
                state.path.append(.recentlyViewedList(RecentlyViewedFeature.State()))
                return .none
                
            case .browseListingsTapped:
                // TODO: 지도 탭으로 네비게이션
                return .none
                
            case let .cardTapped(id):
                // TODO: 매물 상세 뷰 네비게이션 (지도)
                print("선택 매물\(id)") // never used 방지
                return .none
                
            case let .likeButtonTapped(id):
                if let index = state.recentlyViewedItems.firstIndex(where: { $0.id == id }) {
                    state.recentlyViewedItems[index].isLiked.toggle()
                }
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension HomeFeature.Path.State: Equatable {}
