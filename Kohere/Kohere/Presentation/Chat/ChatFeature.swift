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

private extension ChatParticipantRole {
    var userType: UserType {
        switch self {
        case .tenant:
            return .tenant
        case .landlord:
            return .landlord
        }
    }
}

@Reducer
struct ChatFeature {
    enum SwipeAction: Equatable {
        case report
        case block
        case delete
    }

    @Dependency(\.fetchBookingsUseCase)
    var fetchBookingsUseCase
    
    @Reducer
    enum Path {
        case chatDetail(ChatDetailFeature)
        case chatBot(ChatBotFeature)
        case listingDetail(ListingDetailFeature)
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
        case swipeActionTapped(SwipeAction, roomID: Int)
        case popupRequested(AppPopup)
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

            case let .swipeActionTapped(swipeAction, roomID):
                guard state.chatRooms.contains(where: { $0.id == roomID }) else { return .none }
                return .send(.popupRequested(Self.popup(for: swipeAction)))

            case .popupRequested:
                return .none
                
            case .path(.element(id: _, action: .chatDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .chatBot(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .chatBot(.mapTabRequested(diagnosisID)))):
                return .send(.mapTabRequested(diagnosisID: diagnosisID))

            case let .path(.element(id: _, action: .chatDetail(.delegate(.listingDetailRequested(listingID))))):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: listingID,
                            userType: state.participantRole.userType,
                            isApplicationDisabled: true
                        )
                    )
                )
                return .none

            case .path(.element(id: _, action: .listingDetail(.backButtonTapped))):
                _ = state.path.popLast()
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

private extension ChatFeature {
    static func popup(for action: SwipeAction) -> AppPopup {
        let content: (messageKey: String.LocalizationValue, primaryTitleKey: String.LocalizationValue)

        switch action {
        case .report:
            content = ("chat.popup.report.message", "chat.popup.report.primary")
        case .block:
            content = ("chat.popup.block.message", "chat.popup.block.primary")
        case .delete:
            content = ("chat.popup.delete.message", "chat.popup.delete.primary")
        }

        return .action(
            AppPopup.Action(
                message: String(localized: content.messageKey),
                primaryTitle: String(localized: content.primaryTitleKey),
                secondaryTitle: String(localized: "common.cancel")
            )
        )
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

    enum Delegate: Equatable {
        case listingDetailRequested(String)
    }
    
    enum Action {
        case onAppear
        case bookingDetailResponse(Result<BookingDetail, Error>)
        case backButtonTapped
        case viewDetailsButtonTapped
        case delegate(Delegate)
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
                return .send(.delegate(.listingDetailRequested(state.chatRoom.listingID)))

            case .delegate:
                return .none
            }
        }
    }
}
extension ChatFeature.Path.State: Equatable {}
