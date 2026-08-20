//
//  NotificationsFeature.swift
//  Kohere
//
//  Created by soomin on 6/24/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct NotificationsFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case backButtonTapped
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .none
            }
        }
    }
}
