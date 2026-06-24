//
//  RecentlyViewedFeature.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RecentlyViewedFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var items: [ListingItem] = ListingItem.mockList
        var isLoading: Bool = false
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case onAppear
        case cardTapped(id: Int)
        case likeButtonTapped(id: Int)
        case backButtonTapped
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // TODO: 최근 본 매물 API 호출
                return .none
                
            case let .cardTapped(id):
                // TODO: 매물 상세 화면 네비게이션
                print("선택 매물\(id)") // never used 방지
                return .none
                
            case let .likeButtonTapped(id):
                if let index = state.items.firstIndex(where: { $0.id == id }) {
                    state.items[index].isLiked.toggle()
                }
                // TODO: 서버 찜 상태 업데이트 API 호출
                return .none
                
            case .backButtonTapped:
                return .none
            }
        }
    }
}
