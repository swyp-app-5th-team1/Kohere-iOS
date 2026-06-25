//
//  SavedListingsFeature.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SavedListingsFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var items: [ListingItemModel] = ListingItemModel.mockList
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
                // TODO: 찜한 매물 목록 API 호출
                return .none
                
            case let .cardTapped(id):
                // TODO: 해당 매물 상세 정보 뷰로 네비게이션
                print("선택 매물\(id)") // never used 방지
                return .none
                
            case let .likeButtonTapped(id):
                state.items.removeAll { $0.id == id }
                // TODO: 서버에 찜 해제 API 호출
                return .none
                
            case .backButtonTapped:
                return .none
            }
        }
    }
}
