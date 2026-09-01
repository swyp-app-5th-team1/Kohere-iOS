//
//  ChatFeatureTests.swift
//  KohereTests
//
//  Created by Codex on 8/25/26.
//

import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class ChatResponseDTOTests: XCTestCase {
    func testStompGuideDecodesConnectionContract() throws {
        let data = Data(
            """
            {
              "developmentWebSocketUrl": "wss://dev.kohere.app/ws/chat",
              "localWebSocketUrl": "ws://localhost:8080/ws/chat",
              "webSocketEndpoint": "/ws/chat",
              "connectHeaderName": "Authorization",
              "connectHeaderValueFormat": "Bearer {accessToken}",
              "controlQueue": "/user/queue/chat-control",
              "ackQueue": "/user/queue/chat-acks",
              "errorQueue": "/user/queue/chat-errors",
              "roomEventQueue": "/user/queue/chat-room-events",
              "translationQueue": "/user/queue/chat-translations",
              "controlSendDestination": "/app/chat/control/ping",
              "roomSubscribeDestination": "/topic/chat-rooms/{roomId}",
              "messageSendDestination": "/app/chat-rooms/{roomId}/messages",
              "maxTextCodePoints": 3000,
              "heartbeatSeconds": 10
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(ChatStompGuideResponseDTO.self, from: data)

        XCTAssertEqual(response.connectHeaderName, "Authorization")
        XCTAssertEqual(response.maxTextCodePoints, 3_000)
        XCTAssertEqual(response.heartbeatSeconds, 10)
    }

    func testChatMessageHistoryDecodesTextAndBookingCard() throws {
        let data = Data(
            """
            {
              "content": [
                {
                  "messageId": 1,
                  "chatRoomId": 10,
                  "type": "TEXT",
                  "mine": true,
                  "originalContent": "Hello",
                  "sentAt": "2026-08-27T01:00:00Z",
                  "translation": null,
                  "bookingCard": null
                },
                {
                  "messageId": 2,
                  "chatRoomId": 10,
                  "type": "BOOKING_CARD",
                  "mine": false,
                  "originalContent": null,
                  "sentAt": "2026-08-27T01:01:00Z",
                  "translation": null,
                  "bookingCard": {
                    "bookingId": 30,
                    "roomOfferId": "offer-1",
                    "roomOfferName": "Single",
                    "moveInDate": "2026-09-01",
                    "contractPeriod": 6,
                    "deposit": 1000000,
                    "totalAmount": 1500000,
                    "listing": { "listingId": "listing-1", "title": "Home", "address": "Seoul", "monthlyRent": 500000, "thumbnailUrl": null },
                    "applicant": { "userId": 20, "name": "Kim", "gender": "FEMALE", "country": "KR", "countryName": "Korea", "email": "kim@example.com" }
                  }
                }
              ],
              "nextCursor": null,
              "hasNext": false
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(ChatMessagePageResponseDTO.self, from: data)

        XCTAssertEqual(response.content.count, 2)
        XCTAssertEqual(response.content[0].originalContent, "Hello")
        XCTAssertEqual(response.content[1].bookingCard?.bookingId, 30)
    }

    func testChatInquiryResponseDecodesCreatedRoomContract() throws {
        let data = Data(
            """
            {
              "chatRoomId": 10,
              "created": true
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(ChatInquiryResponseDTO.self, from: data)

        XCTAssertEqual(response.chatRoomId, 10)
        XCTAssertTrue(response.created)
    }

    func testChatRoomPageResponseDecodesListContract() throws {
        let data = Data(
            """
            {
              "page": {
                "number": 0,
                "size": 20,
                "totalPages": 1,
                "hasNext": false,
                "totalElements": 1
              },
              "content": [{
                "chatRoomId": 10,
                "myRole": "TENANT",
                "blocked": false,
                "counterpart": { "userId": 20, "displayName": "Landlord" },
                "listing": { "listingId": "listing-1", "title": "Home", "address": "Seoul" },
                "lastMessage": {
                  "messageId": 30,
                  "type": "TEXT",
                  "preview": "Hello",
                  "sentAt": "2026-08-25T01:02:03Z"
                }
              }]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(ChatRoomPageResponseDTO.self, from: data)

        XCTAssertEqual(response.page.number, 0)
        XCTAssertEqual(response.content.first?.chatRoomId, 10)
        XCTAssertEqual(response.content.first?.lastMessage?.type, "TEXT")
    }
}

@MainActor
final class ChatAccessTokenProviderTests: XCTestCase {
    func testExpiredAccessTokenIsReissuedAndSavedBeforeConnecting() async throws {
        let storedAuth = Auth(
            onboardingRequired: false,
            status: .active,
            tokenType: "Bearer",
            accessToken: "expired-access",
            refreshToken: "refresh-token",
            expiresIn: 0,
            expiresAt: Date(timeIntervalSince1970: 0)
        )
        let keychain = ChatKeychainSpy(auth: storedAuth)
        let provider = ChatAccessTokenProvider(
            keychainClient: keychain.client,
            reissueToken: { refreshToken in
                XCTAssertEqual(refreshToken, "refresh-token")
                return AuthToken(
                    tokenType: "Bearer",
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    expiresIn: 3_600
                )
            }
        )

        let accessToken = try await provider.validAccessToken()

        XCTAssertEqual(accessToken, "new-access")
        XCTAssertEqual(keychain.auth?.accessToken, "new-access")
        XCTAssertEqual(keychain.saveCount, 1)
    }

    func testRefreshTransportFailurePreservesStoredSession() async {
        let storedAuth = Auth(
            onboardingRequired: false,
            status: .active,
            tokenType: "Bearer",
            accessToken: "expired-access",
            refreshToken: "refresh-token",
            expiresIn: 0,
            expiresAt: Date(timeIntervalSince1970: 0)
        )
        let keychain = ChatKeychainSpy(auth: storedAuth)
        let provider = ChatAccessTokenProvider(
            keychainClient: keychain.client,
            reissueToken: { _ in throw DataError.transport(message: "offline") }
        )

        do {
            _ = try await provider.validAccessToken()
            XCTFail("네트워크 오류가 전달되어야 합니다.")
        } catch {
            XCTAssertEqual(keychain.auth, storedAuth)
            XCTAssertEqual(keychain.deleteCount, 0)
        }
    }

    private final class ChatKeychainSpy: @unchecked Sendable {
        var auth: Auth?
        var saveCount = 0
        var deleteCount = 0

        init(auth: Auth?) {
            self.auth = auth
        }

        var client: KeychainClient {
            KeychainClient(
                save: { [self] _, data in
                    auth = try JSONDecoder().decode(Auth.self, from: data)
                    saveCount += 1
                },
                read: { [self] _ in
                    try auth.map { try JSONEncoder().encode($0) }
                },
                delete: { [self] _ in
                    auth = nil
                    deleteCount += 1
                }
            )
        }
    }
}

@MainActor
final class ChatFeatureTests: XCTestCase {
    func testRealtimeAcknowledgementCompletesOptimisticMessage() async {
        let clientMessageID = UUID()
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let pending = ChatMessage(
            id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "10:00",
            sentAt: Date(timeIntervalSince1970: 0), clientMessageID: clientMessageID, deliveryStatus: .sending
        )
        let store = TestStore(
            initialState: ChatDetailFeature.State(chatRoom: room, participantRole: .tenant, messages: [pending])
        ) {
            ChatDetailFeature()
        }
        let sentAt = Date(timeIntervalSince1970: 100)

        await store.send(
            .realtimeEvent(
                .acknowledgement(
                    .init(clientMessageID: clientMessageID, messageID: 77, sentAt: sentAt, duplicate: false)
                )
            )
        ) {
            $0.messages[0] = ChatMessage(
                id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "09:01",
                sentAt: sentAt, clientMessageID: clientMessageID, serverMessageID: 77, deliveryStatus: .sent
            )
        }
    }

    func testDisconnectedSendingMessageIsQueuedAndResentWhenReady() async {
        let clientMessageID = UUID()
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let pending = ChatMessage(
            id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "10:00",
            sentAt: Date(timeIntervalSince1970: 0), clientMessageID: clientMessageID, deliveryStatus: .sending
        )
        var initialState = ChatDetailFeature.State(
            chatRoom: room,
            participantRole: .tenant,
            messages: [pending]
        )
        initialState.isRealtimeReady = true
        let store = TestStore(initialState: initialState) {
            ChatDetailFeature()
        }

        await store.send(.realtimeEvent(.connection(.disconnected))) {
            $0.isRealtimeReady = false
            $0.messages[0] = ChatMessage(
                id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "10:00",
                sentAt: Date(timeIntervalSince1970: 0), clientMessageID: clientMessageID, deliveryStatus: .queued
            )
        }

        await store.send(.realtimeEvent(.connection(.ready))) {
            $0.isRealtimeReady = true
            $0.messages[0] = ChatMessage(
                id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "10:00",
                sentAt: Date(timeIntervalSince1970: 0), clientMessageID: clientMessageID, deliveryStatus: .sending
            )
        }
        await store.receive(\.textSendResponse)
    }

    func testInitialHistoryDoesNotOverwriteRealtimeOrPendingMessages() async {
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let pendingID = UUID()
        let pending = ChatMessage(
            id: "client-\(pendingID)", sender: .tenant, originalText: "Pending", timeText: "10:02",
            sentAt: Date(timeIntervalSince1970: 102), clientMessageID: pendingID, deliveryStatus: .queued
        )
        let realtime = ChatMessage(
            id: "server-3", sender: .landlord, originalText: "Realtime", timeText: "10:01",
            sentAt: Date(timeIntervalSince1970: 101), serverMessageID: 3
        )
        var initialState = ChatDetailFeature.State(
            chatRoom: room,
            participantRole: .tenant,
            messages: [realtime, pending]
        )
        initialState.isMessagesLoading = true
        let store = TestStore(initialState: initialState) {
            ChatDetailFeature()
        }
        let history = StoredChatMessage(
            messageID: 1,
            roomID: 1,
            type: .text,
            isMine: false,
            originalContent: "History",
            translatedContent: nil,
            sentAt: Date(timeIntervalSince1970: 100),
            inquiryCard: nil,
            bookingCard: nil
        )

        await store.send(
            .messageHistoryResponse(
                isInitial: true,
                .success(ChatMessagePage(content: [history], nextCursor: nil, hasNext: false))
            )
        ) {
            $0.isMessagesLoading = false
            $0.hasLoadedMessages = true
            $0.messages.insert(
                ChatMessage(
                    id: "server-1", sender: .landlord, originalText: "History", timeText: "09:01",
                    sentAt: Date(timeIntervalSince1970: 100), serverMessageID: 1
                ),
                at: 0
            )
        }
    }

    func testDuplicateHistoryMessageIsReconciledWithAcknowledgedLocalMessage() async {
        let clientMessageID = UUID()
        let sentAt = Date(timeIntervalSince1970: 100)
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let serverCopy = ChatMessage(
            id: "server-77", sender: .tenant, originalText: "Hello", timeText: "09:01",
            sentAt: sentAt, serverMessageID: 77
        )
        let pending = ChatMessage(
            id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "09:00",
            sentAt: Date(timeIntervalSince1970: 99), clientMessageID: clientMessageID, deliveryStatus: .sending
        )
        let store = TestStore(
            initialState: ChatDetailFeature.State(
                chatRoom: room,
                participantRole: .tenant,
                messages: [serverCopy, pending]
            )
        ) {
            ChatDetailFeature()
        }

        await store.send(
            .realtimeEvent(
                .acknowledgement(
                    .init(clientMessageID: clientMessageID, messageID: 77, sentAt: sentAt, duplicate: true)
                )
            )
        ) {
            $0.messages = [
                ChatMessage(
                    id: "client-\(clientMessageID)", sender: .tenant, originalText: "Hello", timeText: "09:01",
                    sentAt: sentAt, clientMessageID: clientMessageID, serverMessageID: 77, deliveryStatus: .sent
                )
            ]
        }
    }

    func testInitialPageReplacesRoomsAndUpdatesPagination() async {
        let store = TestStore(initialState: ChatFeature.State()) {
            ChatFeature()
        }
        let page = ChatRoomPage(
            content: [makeRoom(roomID: 1)],
            page: PageInfo(number: 0, size: 20, totalElements: 2, totalPages: 2, hasNext: true)
        )

        await store.send(.chatRoomListResponse(requestedPage: 0, .success(page))) {
            $0.chatRooms = [ChatRoomModel(room: self.makeRoom(roomID: 1))]
            $0.hasLoadedInitialPage = true
            $0.nextPage = 1
            $0.hasNextPage = true
        }
    }

    func testNextPageAppendsOnlyNewRooms() async {
        var initialState = ChatFeature.State(chatRooms: [ChatRoomModel(room: makeRoom(roomID: 1))])
        initialState.isLoading = true
        initialState.hasLoadedInitialPage = true
        initialState.nextPage = 1
        initialState.hasNextPage = true

        let store = TestStore(initialState: initialState) {
            ChatFeature()
        }
        let page = ChatRoomPage(
            content: [makeRoom(roomID: 1), makeRoom(roomID: 2)],
            page: PageInfo(number: 1, size: 20, totalElements: 2, totalPages: 2, hasNext: false)
        )

        await store.send(.chatRoomListResponse(requestedPage: 1, .success(page))) {
            $0.chatRooms.append(ChatRoomModel(room: self.makeRoom(roomID: 2)))
            $0.isLoading = false
            $0.nextPage = 2
            $0.hasNextPage = false
        }
    }

    func testBookingConfirmationRoomListResponseOpensMatchingChatRoom() async {
        var initialState = ChatFeature.State(participantRole: .tenant)
        initialState.isLoading = true
        initialState.pendingNavigationListingID = "listing-2"
        let store = TestStore(initialState: initialState) {
            ChatFeature()
        }
        let matchingRoom = makeRoom(roomID: 2)
        let page = ChatRoomPage(
            content: [makeRoom(roomID: 1), matchingRoom],
            page: PageInfo(number: 0, size: 20, totalElements: 2, totalPages: 1, hasNext: false)
        )

        await store.send(.chatRoomListResponse(requestedPage: 0, .success(page))) {
            $0.isLoading = false
            $0.hasLoadedInitialPage = true
            $0.nextPage = 1
            $0.hasNextPage = false
            $0.chatRooms = [
                ChatRoomModel(room: self.makeRoom(roomID: 1)),
                ChatRoomModel(room: matchingRoom)
            ]
            $0.pendingNavigationListingID = nil
            $0.path.append(
                .chatDetail(
                    ChatDetailFeature.State(
                        chatRoom: ChatRoomModel(room: matchingRoom),
                        participantRole: .tenant,
                        shouldRetryBookingCard: true
                    )
                )
            )
        }
    }

    func testDetailResponseUsesServerRoleAndRoomInformation() async {
        let initialRoom = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let store = TestStore(
            initialState: ChatDetailFeature.State(chatRoom: initialRoom, participantRole: .tenant)
        ) {
            ChatDetailFeature()
        }
        let updatedRoom = makeRoom(roomID: 1, role: .landlord)

        await store.send(.chatRoomResponse(.success(updatedRoom))) {
            $0.chatRoom = ChatRoomModel(room: self.makeRoom(roomID: 1, role: .landlord))
            $0.participantRole = .landlord
        }
    }

    func testInquiryRoomShowsApplicationBannerAndOpensEnabledApplicationDetail() async {
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let store = TestStore(initialState: ChatDetailFeature.State(chatRoom: room, participantRole: .tenant,
                                                                    hasSubmittedApplication: false,
                                                                    showsInquiryCard: true)) {
            ChatDetailFeature()
        }

        XCTAssertTrue(store.state.showsApplicationBanner)

        await store.send(.applicationBannerTapped)
        await store.receive(\.delegate.listingDetailRequested)
    }

    func testSubmittedApplicationCardOpensDetailWithApplicationEnabled() async {
        let room = ChatRoomModel(room: makeRoom(roomID: 1, role: .tenant))
        let store = TestStore(
            initialState: ChatDetailFeature.State(
                chatRoom: room,
                participantRole: .tenant,
                hasSubmittedApplication: true
            )
        ) {
            ChatDetailFeature()
        }

        await store.send(.viewDetailsButtonTapped(listingID: "listing-1"))
        await store.receive(\.delegate.listingDetailRequested)
    }

    func testApplicationRequestFromChatListingDetailOpensApplicationFlow() async throws {
        var initialState = ChatFeature.State(participantRole: .tenant)
        initialState.path.append(.listingDetail(ListingDetailFeature.State(listingID: "listing-1",
                                                                           userType: .tenant,
                                                                           appLanguage: .english)))
        let detailID = try XCTUnwrap(initialState.path.ids.last)
        let store = TestStore(initialState: initialState) {
            ChatFeature()
        }

        await store.send(
            .path(
                .element(
                    id: detailID,
                    action: .listingDetail(
                        .delegate(
                            .applicationRequested(listingID: "listing-1", listingTitle: "Home",
                                                  roomOfferID: "offer-1", roomTypeName: "Single",
                                                  roomPricingText: "₩500,000")
                        )
                    )
                )
            )
        ) {
            $0.path.append(.listingApplication(ListingApplicationFeature.State(listingID: "listing-1",
                                                                               listingTitle: "Home",
                                                                               roomOfferID: "offer-1",
                                                                               roomTypeName: "Single",
                                                                               roomPricingText: "₩500,000",
                                                                               appLanguage: .english)))
        }
    }

    private func makeRoom(roomID: Int, role: ChatRoomRole = .tenant) -> ChatRoom {
        ChatRoom(
            roomID: roomID,
            myRole: role,
            listing: ChatRoomListing(listingID: "listing-\(roomID)", title: "Home", address: "Seoul"),
            counterpart: ChatRoomCounterpart(userID: 100, displayName: "Counterpart"),
            isBlocked: false,
            lastMessage: ChatRoomLastMessage(
                messageID: 200,
                type: .text,
                preview: "Hello",
                sentAt: Date(timeIntervalSince1970: 0)
            )
        )
    }
}
