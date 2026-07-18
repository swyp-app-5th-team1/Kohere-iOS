//
//  ChatView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct ChatView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatFeature>
    @State private var revealedChatRoomID: Int?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            KohereNavigationBar(
                left: .smallLogo,
                center: .text(String(localized: "chat.title"), style: .label1Semibold)
            )
            
            roomFinderBanner
            
            if store.chatRooms.isEmpty {
                KohereEmptyView(
                    title: String(localized: "chat.empty.title"),
                    fontStyle: .label2Semibold,
                    fontColor: .neutral40
                )
                .padding(.bottom, 100)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        ForEach(store.chatRooms) { room in
                            ChatRoomRowCell(
                                item: room,
                                participantRole: store.participantRole,
                                isRevealed: revealedChatRoomID == room.id,
                                onTap: { id in
                                    store.send(.chatRoomTapped(id: id))
                                },
                                onReveal: {
                                    revealedChatRoomID = room.id
                                },
                                onClose: {
                                    if revealedChatRoomID == room.id {
                                        revealedChatRoomID = nil
                                    }
                                },
                                onReport: {
                                    store.send(.swipeActionTapped(.report, roomID: room.id))
                                },
                                onBlock: {
                                    store.send(.swipeActionTapped(.block, roomID: room.id))
                                },
                                onDelete: {
                                    store.send(.swipeActionTapped(.delete, roomID: room.id))
                                }
                            )
                        }
                    }
                }
            }
        }
        .background(.backgroundNormalNormal)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var roomFinderBanner: some View {
        Button {
            store.send(.roomFinderBannerTapped)
        } label: {
            Image(.chatBanner)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .overlay(
                    Text("common.roomFinderBanner.title")
                        .kohereTextStyle(.heading3Semibold)
                        .foregroundStyle(.neutral5)
                        .padding(.leading, 16),
                    alignment: .leading
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.roomFinderBanner.accessibility"))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
