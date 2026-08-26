//
//  ChatDetailFeature.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatDetailFeature {
    @Dependency(\.fetchChatRoomUseCase)
    var fetchChatRoomUseCase
    @Dependency(\.fetchChatMessagesUseCase)
    var fetchChatMessagesUseCase

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoomModel
        var participantRole: ChatRoomRole
        var hasSubmittedApplication: Bool
        var messages: [ChatMessage]
        var messageText = ""
        var isMoreMenuPresented = false
        var isLoading = false
        var isMessagesLoading = false
        var hasLoadedMessages = false
        var nextCursor: String?
        var hasOlderMessages = false
        var shouldRetryBookingCard: Bool
        var showsInquiryCard: Bool
        var errorMessage: String?

        var showsApplicationBanner: Bool {
            participantRole == .tenant && showsInquiryCard && hasLoadedMessages && !hasSubmittedApplication
        }

        var showsKeywordSuggestions: Bool {
            participantRole == .tenant
        }

        init(
            chatRoom: ChatRoomModel,
            participantRole: ChatRoomRole = .tenant,
            hasSubmittedApplication: Bool = false,
            messages: [ChatMessage] = [],
            shouldRetryBookingCard: Bool = false,
            showsInquiryCard: Bool = false
        ) {
            self.chatRoom = chatRoom
            self.participantRole = participantRole
            self.hasSubmittedApplication = hasSubmittedApplication
            self.messages = messages
            self.shouldRetryBookingCard = shouldRetryBookingCard
            self.showsInquiryCard = showsInquiryCard
        }
    }

    @CasePathable
    enum Delegate: Equatable {
        case listingDetailRequested(String, isApplicationDisabled: Bool)
        case swipeActionRequested(ChatFeature.SwipeAction, roomID: Int)
    }
    
    // MARK: - Action

    enum Action {
        case onAppear
        case chatRoomResponse(Result<ChatRoom, Error>)
        case messageHistoryResponse(isInitial: Bool, Result<ChatMessagePage, Error>)
        case loadPreviousMessages
        case retryBookingCard
        case backButtonTapped
        case viewDetailsButtonTapped
        case applicationBannerTapped
        case messageTextChanged(String)
        case keywordTapped(String)
        case sendButtonTapped
        case moreButtonTapped
        case moreMenuDismissed
        case moreMenuActionTapped(ChatFeature.SwipeAction)
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
                let roomID = state.chatRoom.roomID
                let fetchChatRoom = fetchChatRoomUseCase
                let roomEffect: Effect<Action> = .run { send in
                    do {
                        let room = try await fetchChatRoom.execute(roomID)
                        await send(.chatRoomResponse(.success(room)))
                    } catch {
                        await send(.chatRoomResponse(.failure(error)))
                    }
                }
                guard !state.hasLoadedMessages, !state.isMessagesLoading else { return roomEffect }
                state.isMessagesLoading = true
                return .merge(roomEffect, fetchMessages(roomID: roomID, cursor: nil, isInitial: true))

            case let .chatRoomResponse(.success(room)):
                state.isLoading = false
                state.errorMessage = nil
                state.chatRoom = ChatRoomModel(room: room)
                state.participantRole = room.myRole
                return .none

            case let .chatRoomResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .messageHistoryResponse(isInitial, .success(page)):
                state.isMessagesLoading = false
                state.hasLoadedMessages = true
                state.nextCursor = page.nextCursor
                state.hasOlderMessages = page.hasNext
                let mapped = page.content.map { Self.message(from: $0, room: state.chatRoom, role: state.participantRole) }
                if isInitial {
                    state.messages = Array(mapped.reversed())
                } else {
                    state.messages.insert(contentsOf: Array(mapped.reversed()), at: 0)
                }
                if page.content.contains(where: { $0.type == .bookingCard }) {
                    state.hasSubmittedApplication = true
                    state.shouldRetryBookingCard = false
                    return .none
                }
                guard isInitial, state.shouldRetryBookingCard else { return .none }
                state.shouldRetryBookingCard = false
                return .run { send in
                    try? await Task.sleep(for: .seconds(1))
                    await send(.retryBookingCard)
                }

            case let .messageHistoryResponse(_, .failure(error)):
                state.isMessagesLoading = false
                state.hasLoadedMessages = true
                state.errorMessage = error.localizedDescription
                return .none

            case .loadPreviousMessages:
                guard state.hasOlderMessages, !state.isMessagesLoading, let cursor = state.nextCursor else { return .none }
                state.isMessagesLoading = true
                return fetchMessages(roomID: state.chatRoom.roomID, cursor: cursor, isInitial: false)

            case .retryBookingCard:
                guard !state.isMessagesLoading else { return .none }
                state.isMessagesLoading = true
                return fetchMessages(roomID: state.chatRoom.roomID, cursor: nil, isInitial: true)

            case .backButtonTapped:
                return .none

            case .viewDetailsButtonTapped:
                return .send(
                    .delegate(
                        .listingDetailRequested(
                            state.chatRoom.listingID,
                            isApplicationDisabled: state.hasSubmittedApplication
                        )
                    )
                )

            case .applicationBannerTapped:
                return .send(
                    .delegate(
                        .listingDetailRequested(
                            state.chatRoom.listingID,
                            isApplicationDisabled: false
                        )
                    )
                )

            case let .messageTextChanged(text):
                state.messageText = text
                return .none

            case let .keywordTapped(keyword):
                let message = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                state.messages.append(Self.localMessage(message, sender: state.participantRole))
                // TODO: api 연동
                return .none

            case .sendButtonTapped:
                let message = state.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !message.isEmpty else { return .none }
                state.messages.append(Self.localMessage(message, sender: state.participantRole))
                state.messageText = ""
                // TODO: api 연동
                return .none

            case .moreButtonTapped:
                state.isMoreMenuPresented.toggle()
                return .none

            case .moreMenuDismissed:
                state.isMoreMenuPresented = false
                return .none

            case let .moreMenuActionTapped(swipeAction):
                state.isMoreMenuPresented = false
                return .send(.delegate(.swipeActionRequested(swipeAction, roomID: state.chatRoom.roomID)))

            case .delegate:
                return .none
            }
        }
    }

    private static func currentTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func localMessage(_ text: String, sender: ChatRoomRole) -> ChatMessage {
        ChatMessage(sender: sender, originalText: text, timeText: currentTimeText(), sentAt: Date())
    }

    private func fetchMessages(roomID: Int, cursor: String?, isInitial: Bool) -> Effect<Action> {
        let fetch = fetchChatMessagesUseCase
        return .run { send in
            do {
                let page = try await fetch.execute(roomID, cursor, nil, 30)
                await send(.messageHistoryResponse(isInitial: isInitial, .success(page)))
            } catch {
                await send(.messageHistoryResponse(isInitial: isInitial, .failure(error)))
            }
        }
    }

    private static func message(from message: StoredChatMessage, room: ChatRoomModel, role: ChatRoomRole) -> ChatMessage {
        let sender: ChatRoomRole = message.isMine ? role : (role == .tenant ? .landlord : .tenant)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let card = message.bookingCard.map { booking in
            ChatRoomModel(roomID: room.roomID, myRole: role,
                          listingID: booking.listing?.listingID ?? room.listingID,
                          listingName: booking.listing?.title ?? room.listingName,
                          location: booking.listing?.address ?? room.location,
                          counterpartName: room.counterpartName, thumbnailURL: booking.listing?.thumbnailURL,
                          createdAt: message.sentAt, applicantName: booking.applicant?.name ?? "N/A",
                          applicantGenderCode: booking.applicant?.gender ?? "",
                          applicantCountryCode: booking.applicant?.country ?? "",
                          applicantCountryName: booking.applicant?.countryName ?? "",
                          applicantEmail: booking.applicant?.email ?? "N/A",
                          roomType: booking.roomOfferName ?? "N/A", moveInDate: booking.moveInDate,
                          leaseTermMonths: booking.contractPeriod ?? 0, depositAmount: booking.deposit,
                          totalCostAmount: booking.totalAmount,
                          pricePerMonthAmount: booking.listing?.monthlyRent)
        }
        return ChatMessage(id: "server-\(message.messageID)", sender: sender,
                           originalText: message.originalContent ?? "", translatedText: message.translatedContent,
                           timeText: formatter.string(from: message.sentAt), sentAt: message.sentAt, bookingCard: card)
    }
}
