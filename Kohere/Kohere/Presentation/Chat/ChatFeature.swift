//
//  ChatFeature.swift
//  Kohere
//
//  Created by soomin on 6/18/26.
//

import ComposableArchitecture
import Foundation

private extension ChatRoomRole {
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

    @Dependency(\.fetchChatRoomsUseCase)
    var fetchChatRoomsUseCase

    @Dependency(\.mutateBookingUseCase)
    var mutateBookingUseCase
    
    @Reducer
    enum Path {
        case chatDetail(ChatDetailFeature)
        case chatBot(ChatBotFeature)
        case listingDetail(ListingDetailFeature)
        case listingApplication(ListingApplicationFeature)
        case listingApplicationPrivacyWeb(ListingApplicationPrivacyWebFeature)
        case report(ChatReportFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var chatRooms: [ChatRoomModel] = []
        var participantRole: ChatRoomRole
        var appLanguage: AppLanguage
        var isContentAvailable = false
        var isLoading = false
        var hasLoadedInitialPage = false
        var nextPage = 0
        var hasNextPage = false
        var pendingSwipeAction: SwipeAction?
        var pendingSwipeRoomID: Int?
        var errorMessage: String?
        var pendingBookingRoomIDs: Set<Int> = []
        
        init(
            chatRooms: [ChatRoomModel] = [],
            participantRole: ChatRoomRole = .landlord,
            appLanguage: AppLanguage = .english
        ) {
            self.chatRooms = chatRooms
            self.participantRole = participantRole
            self.appLanguage = appLanguage
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case chatRoomListResponse(requestedPage: Int, Result<ChatRoomPage, Error>)
        case chatRoomAppeared(roomID: Int)
        case path(StackActionOf<Path>)
        case chatRoomTapped(roomID: Int)
        case swipeActionTapped(SwipeAction, roomID: Int)
        case reportDetailsRequested(roomID: Int)
        case swipeActionConfirmed(SwipeAction, roomID: Int)
        case swipeActionResponse(SwipeAction, roomID: Int, Result<Void, Error>)
        case popupRequested(AppPopup)
        case roomFinderBannerTapped
        case mapRequested(MapEntryRequest)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.isContentAvailable,
                      !state.hasLoadedInitialPage,
                      !state.isLoading
                else { return .none }
                return fetchChatRooms(page: 0, state: &state)

            case let .chatRoomListResponse(requestedPage, .success(page)):
                state.isLoading = false
                state.errorMessage = nil
                state.hasLoadedInitialPage = true
                state.nextPage = (page.page.number ?? requestedPage) + 1
                state.hasNextPage = page.page.hasNext ?? false

                let rooms = page.content.map(ChatRoomModel.init(room:))
                if requestedPage == 0 {
                    state.chatRooms = rooms
                } else {
                    let existingRoomIDs = Set(state.chatRooms.map(\.roomID))
                    state.chatRooms.append(contentsOf: rooms.filter { !existingRoomIDs.contains($0.roomID) })
                }
                return .none
                
            case let .chatRoomListResponse(_, .failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .chatRoomAppeared(roomID):
                guard roomID == state.chatRooms.last?.roomID,
                      state.hasNextPage,
                      !state.isLoading
                else { return .none }
                return fetchChatRooms(page: state.nextPage, state: &state)
                
            case let .chatRoomTapped(roomID):
                if let selectedRoom = state.chatRooms.first(where: { $0.roomID == roomID }) {
                    let shouldRetry = state.pendingBookingRoomIDs.remove(roomID) != nil
                    state.path.append(.chatDetail(ChatDetailFeature.State(chatRoom: selectedRoom,
                                                                          participantRole: selectedRoom.myRole,
                                                                          shouldRetryBookingCard: shouldRetry)))
                }
                return .none

            case let .swipeActionTapped(swipeAction, roomID):
                guard state.chatRooms.contains(where: { $0.roomID == roomID }) else { return .none }
                return .send(.popupRequested(Self.popup(for: swipeAction, roomID: roomID, language: state.appLanguage)))

            case let .reportDetailsRequested(roomID):
                guard state.chatRooms.contains(where: { $0.roomID == roomID }) else { return .none }
                state.path.append(.report(ChatReportFeature.State(roomID: roomID, appLanguage: state.appLanguage)))
                return .none

            case let .swipeActionConfirmed(swipeAction, roomID):
                guard state.pendingSwipeAction == nil,
                      state.chatRooms.contains(where: { $0.roomID == roomID })
                else { return .none }

                state.pendingSwipeAction = swipeAction
                state.pendingSwipeRoomID = roomID
                let mutateBooking = mutateBookingUseCase
                return .run { send in
                    do {
                        try await mutateBooking.execute(swipeAction.bookingMutation, roomID)
                        await send(.swipeActionResponse(swipeAction, roomID: roomID, .success(())))
                    } catch {
                        await send(.swipeActionResponse(swipeAction, roomID: roomID, .failure(error)))
                    }
                }

            case let .swipeActionResponse(swipeAction, roomID, .success):
                guard state.pendingSwipeAction == swipeAction,
                      state.pendingSwipeRoomID == roomID
                else { return .none }

                state.pendingSwipeAction = nil
                state.pendingSwipeRoomID = nil
                if swipeAction == .block || swipeAction == .delete {
                    state.chatRooms.removeAll { $0.roomID == roomID }
                }
                return .send(.popupRequested(Self.resultPopup(for: swipeAction, succeeded: true, language: state.appLanguage)))

            case let .swipeActionResponse(swipeAction, roomID, .failure):
                guard state.pendingSwipeAction == swipeAction,
                      state.pendingSwipeRoomID == roomID
                else { return .none }

                state.pendingSwipeAction = nil
                state.pendingSwipeRoomID = nil
                return .send(.popupRequested(Self.resultPopup(for: swipeAction, succeeded: false, language: state.appLanguage)))

            case .popupRequested:
                return .none
                
            case .path(.element(id: _, action: .chatDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return fetchChatRooms(page: 0, state: &state)

            case .path(.element(id: _, action: .chatBot(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .chatBot(.mapRequested(request)))):
                return .send(.mapRequested(request))

            case let .path(.element(id: _, action: .chatDetail(.delegate(.listingDetailRequested(listingID, isApplicationDisabled))))):
                state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID,
                                                                            userType: state.participantRole.userType,
                                                                            appLanguage: state.appLanguage,
                                                                            isApplicationDisabled: isApplicationDisabled)))
                return .none

            case let .path(.element(id: _, action: .chatDetail(.delegate(.swipeActionRequested(swipeAction, roomID))))):
                return .send(.swipeActionTapped(swipeAction, roomID: roomID))

            case .path(.element(id: _, action: .listingDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(
                id: _,
                action: .listingDetail(
                    .delegate(
                        .applicationRequested(
                            listingID,
                            listingTitle,
                            roomOfferID,
                            roomTypeName,
                            roomPricingText
                        )
                    )
                )
            )):
                state.path.append(.listingApplication(ListingApplicationFeature.State(listingID: listingID,
                                                                                      listingTitle: listingTitle,
                                                                                      roomOfferID: roomOfferID,
                                                                                      roomTypeName: roomTypeName,
                                                                                      roomPricingText: roomPricingText,
                                                                                      appLanguage: state.appLanguage)))
                return .none

            case let .path(.element(id: _, action: .listingDetail(.delegate(.inquiryChatRoomRequested(roomID, listingID))))):
                let room = ChatRoomModel(roomID: roomID, myRole: .tenant, listingID: listingID,
                                         listingName: "", location: "")
                state.path.removeAll()
                state.path.append(.chatDetail(ChatDetailFeature.State(chatRoom: room, participantRole: .tenant,
                                                                      hasSubmittedApplication: false,
                                                                      showsInquiryCard: true)))
                return .none

            case .path(.element(id: _, action: .listingApplication(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .listingApplication(.inquiryResponse(.success(inquiry))))):
                state.pendingBookingRoomIDs.insert(inquiry.roomID)
                state.hasLoadedInitialPage = false
                return .none

            case let .path(.element(
                id: _,
                action: .listingApplication(.delegate(.privacyDocumentRequested(section)))
            )):
                state.path.append(.listingApplicationPrivacyWeb(
                    ListingApplicationPrivacyWebFeature.State(section: section, appLanguage: state.appLanguage)
                ))
                return .none

            case .path(.element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(
                id: _,
                action: .listingApplication(.delegate(.listingDetailRequested(listingID)))
            )):
                state.path.removeAll()
                state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID,
                                                                            userType: state.participantRole.userType,
                                                                            appLanguage: state.appLanguage,
                                                                            isApplicationDisabled: true)))
                return .none

            case .path(.element(id: _, action: .listingApplication(.delegate(.chatTabRequested)))):
                state.path.removeAll()
                return fetchChatRooms(page: 0, state: &state)

            case .path(.element(id: _, action: .report(.closeButtonTapped))):
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

    private func fetchChatRooms(page: Int, state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil

        let fetchChatRooms = fetchChatRoomsUseCase
        return .run { send in
            do {
                let response = try await fetchChatRooms.execute(page, 20)
                await send(.chatRoomListResponse(requestedPage: page, .success(response)))
            } catch {
                await send(.chatRoomListResponse(requestedPage: page, .failure(error)))
            }
        }
    }
}

private extension ChatFeature.SwipeAction {
    var bookingMutation: BookingMutation {
        switch self {
        case .report:
            return .report
        case .block:
            return .block
        case .delete:
            return .delete
        }
    }
}

extension ChatFeature.State {
    mutating func applyUserType(_ userType: UserType) -> Bool {
        guard let updatedParticipantRole = ChatRoomRole(userType: userType) else { return false }
        isContentAvailable = true
        guard participantRole != updatedParticipantRole else { return false }

        participantRole = updatedParticipantRole
        path.removeAll()
        chatRooms = []
        isLoading = false
        hasLoadedInitialPage = false
        nextPage = 0
        hasNextPage = false
        pendingSwipeAction = nil
        pendingSwipeRoomID = nil
        errorMessage = nil
        pendingBookingRoomIDs = []

        return true
    }
}

extension ChatFeature.Path.State: Equatable {}
