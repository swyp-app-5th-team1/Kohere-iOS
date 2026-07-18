//
//  ChatDetailView.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatDetailView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatDetailFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            Rectangle()
                .fill(Color.neutral10)
                .frame(height: 1)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if !store.chatRoom.dateText.isEmpty {
                        Text(store.chatRoom.dateText)
                            .kohereTextStyle(.caption1Regular)
                            .foregroundColor(.neutral40)
                    }
                    
                    chatContent
                }
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .background(.backgroundNormalNormal)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundNormalNormal)
        .onAppear {
            store.send(.onAppear)
        }
    }
}

private extension ChatDetailView {
    var navigationBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(store.chatRoom.listingName)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)
                
                Text(store.chatRoom.location)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundColor(.neutral50)
            }
            .lineLimit(1)
            
            HStack(spacing: 0) {
                Button {
                    store.send(.backButtonTapped)
                } label: {
                    Image(.chevronLeft24)
                        .renderingMode(.template)
                        .foregroundColor(.labelNormal)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 56)
        .background(.backgroundNormalNormal)
    }
    
    @ViewBuilder var chatContent: some View {
        switch store.participantRole {
        case .tenant:
            tenantContent
            
        case .landlord:
            landlordContent
        }
    }
    
    var tenantContent: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                Spacer()
                
                if !store.chatRoom.timeText.isEmpty {
                    Text(store.chatRoom.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral20)
                }
                
                MoveInApplicationCardView(item: store.chatRoom)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.viewDetailsButtonTapped)
                    }
            }
            .padding(.horizontal, 16)
            
            applicationSentMessage
                .padding(.top, 12)
        }
    }
    
    var landlordContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                landlordAvatar
                
                landlordRequestMessage
                
                Spacer(minLength: 0)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                Color.clear
                    .frame(width: 32, height: 1)
                
                MoveInApplicationCardView(
                    item: store.chatRoom,
                    mode: .landlord
                )
                
                if !store.chatRoom.timeText.isEmpty {
                    Text(store.chatRoom.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(.neutral20)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    var applicationSentMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.lineNeutral, lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("chat.applicationSent.title")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.staticBlack)
                
                Text("chat.applicationSent.message")
                    .kohereTextStyle(.body2Regular)
                    .foregroundStyle(.staticBlack)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 248, alignment: .leading)
            .background(Color.statusBlue5)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 0,
                        bottomLeading: 12,
                        bottomTrailing: 12,
                        topTrailing: 12
                    )
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 0,
                        bottomLeading: 12,
                        bottomTrailing: 12,
                        topTrailing: 12
                    )
                )
                    .stroke(Color.lineNeutral, lineWidth: 1)
            )
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }
    
    var landlordAvatar: some View {
        Image(.personFill24)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.secondary5)
            .frame(width: 24, height: 24)
            .frame(width: 32, height: 32)
            .background(.primary10)
            .clipShape(Circle())
    }
    
    var landlordRequestMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chat.applicationReceived.title")
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.staticBlack)
            
            Text("chat.applicationReceived.message")
                .kohereTextStyle(.body2Regular)
                .foregroundStyle(.staticBlack)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 270, alignment: .leading)
        .background(.backgroundNormalAlternative)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 12
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 12
            )
            .stroke(.lineNeutral, lineWidth: 1)
        )
    }
}
