//
//  ChatFeature.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import ComposableArchitecture

@Reducer
struct ChatFeature {
    @Reducer
    enum Path {
        case chatDetail(ChatDetailFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var chatRooms: [ChatRoomModel] = []
        
        init(chatRooms: [ChatRoomModel] = ChatRoomModel.mockChatRooms) {
            self.chatRooms = chatRooms
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case path(StackActionOf<Path>)
        case chatRoomTapped(id: Int)
        case searchButtonTapped
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .chatRoomTapped(id):
                if let selectedRoom = state.chatRooms.first(where: { $0.id == id }) {
                    state.path.append(.chatDetail(ChatDetailFeature.State(chatRoom: selectedRoom)))
                }
                return .none
                
            case .path(.element(id: _, action: .chatDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none
                
            case .searchButtonTapped:
                // TODO: 검색 기능 구현 예정
                return .none
                
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

@Reducer
struct ChatDetailFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoomModel
    }
    
    // MARK: - Action
    
    enum Action {
        case backButtonTapped
        case viewDetailsButtonTapped
    }
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none
            case .viewDetailsButtonTapped:
                print("채팅방 id: \(state.chatRoom.id)")
                return .none
            }
        }
    }
}
extension ChatFeature.Path.State: Equatable {}
