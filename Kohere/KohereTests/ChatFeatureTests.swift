//
//  ChatFeatureTests.swift
//  KohereTests
//
//  Created by Codex on 8/25/26.
//

import ComposableArchitecture
import XCTest
@testable import Kohere

final class ChatResponseDTOTests: XCTestCase {
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
final class ChatFeatureTests: XCTestCase {
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
