//
//  ChatFeature.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import ComposableArchitecture
import Foundation

enum ChatParticipantRole: Equatable {
    case tenant
    case landlord

    init?(userType: UserType) {
        switch userType {
        case .tenant:
            self = .tenant
        case .landlord:
            self = .landlord
        case .unknown:
            return nil
        }
    }
}

@Reducer
struct ChatFeature {
    @Dependency(\.fetchBookingsUseCase)
    var fetchBookingsUseCase
    
    @Reducer
    enum Path {
        case chatDetail(ChatDetailFeature)
        case chatBot(ChatBotFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var chatRooms: [ChatRoomModel] = []
        var participantRole: ChatParticipantRole
        var isLoading = false
        var errorMessage: String?
        
        init(
            chatRooms: [ChatRoomModel] = [],
            participantRole: ChatParticipantRole = .landlord
        ) {
            self.chatRooms = chatRooms
            self.participantRole = participantRole
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case bookingListResponse(Result<BookingPage, Error>)
        case path(StackActionOf<Path>)
        case chatRoomTapped(id: Int)
        case searchButtonTapped
        case roomFinderBannerTapped
        case mapRequested(MapEntryRequest)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let fetchBookings = fetchBookingsUseCase
                return .run { send in
                    do {
                        let page = try await fetchBookings.execute(0, 20)
                        await send(.bookingListResponse(.success(page)))
                    } catch {
                        await send(.bookingListResponse(.failure(error)))
                    }
                }
                
            case let .bookingListResponse(.success(page)):
                state.isLoading = false
                state.errorMessage = nil
                state.chatRooms = page.content.map(ChatRoomModel.init(summary:))
                return .none
                
            case let .bookingListResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .chatRoomTapped(id):
                if let selectedRoom = state.chatRooms.first(where: { $0.id == id }) {
                    state.path.append(
                        .chatDetail(
                            ChatDetailFeature.State(
                                chatRoom: selectedRoom,
                                participantRole: state.participantRole
                            )
                        )
                    )
                }
                return .none
                
            case .path(.element(id: _, action: .chatDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .chatBot(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .chatBot(.mapRequested(request)))):
                return .send(.mapRequested(request))
                
            case .searchButtonTapped:
                // TODO: 검색 기능 구현 예정
                return .none

            case .roomFinderBannerTapped:
                state.path.append(.chatBot(ChatBotFeature.State()))
                return .none

            case .mapRequested:
                return .none
                
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension ChatFeature.State {
    mutating func applyUserType(_ userType: UserType) -> Bool {
        guard let updatedParticipantRole = ChatParticipantRole(userType: userType) else { return false }
        guard participantRole != updatedParticipantRole else { return false }

        participantRole = updatedParticipantRole
        path.removeAll()
        chatRooms = []
        isLoading = false
        errorMessage = nil

        return true
    }
}

@Reducer
struct ChatDetailFeature {
    @Dependency(\.fetchBookingDetailUseCase)
    var fetchBookingDetailUseCase
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoomModel
        var participantRole: ChatParticipantRole
        var isLoading = false
        var errorMessage: String?
        
        init(
            chatRoom: ChatRoomModel,
            participantRole: ChatParticipantRole = .tenant
        ) {
            self.chatRoom = chatRoom
            self.participantRole = participantRole
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case bookingDetailResponse(Result<BookingDetail, Error>)
        case backButtonTapped
        case viewDetailsButtonTapped
    }
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let bookingID = state.chatRoom.id
                let fetchBookingDetail = fetchBookingDetailUseCase
                return .run { send in
                    do {
                        let detail = try await fetchBookingDetail.execute(bookingID)
                        await send(.bookingDetailResponse(.success(detail)))
                    } catch {
                        await send(.bookingDetailResponse(.failure(error)))
                    }
                }
                
            case let .bookingDetailResponse(.success(detail)):
                state.isLoading = false
                state.errorMessage = nil
                state.chatRoom = ChatRoomModel(detail: detail, fallback: state.chatRoom)
                return .none
                
            case let .bookingDetailResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
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
