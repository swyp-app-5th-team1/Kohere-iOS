//
//  ChatView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            KohereNavigationBar(
                left: .smallLogo,
                center: .text("Chat", style: .label1Semibold),
                right: .searchButton({ store.send(.searchButtonTapped) })
            )
            
            Image(.chatBanner)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .overlay(
                    Text("Find your perfect room\nin 1 minute.")
                        .kohereTextStyle(.heading3Semibold)
                        .foregroundStyle(.neutral5)
                        .padding(.leading, 16), alignment: .leading
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            if store.chatRooms.isEmpty {
                KohereEmptyView(
                    title: "No messages yet\nContact a host to start chatting",
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
                                participantRole: store.participantRole
                            ) { id in
                                store.send(.chatRoomTapped(id: id))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
