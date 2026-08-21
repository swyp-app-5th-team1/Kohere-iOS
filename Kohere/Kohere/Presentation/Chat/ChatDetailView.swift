//
//  ChatDetailView.swift
//  Kohere
//
//  Created by soomin on 6/29/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct ChatDetailView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<ChatDetailFeature>
    @Environment(\.locale)
    private var locale
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ChatDetailNavigationBar(
                    title: store.chatRoom.listingName,
                    subtitle: store.chatRoom.location,
                    onBackTapped: { store.send(.backButtonTapped) },
                    onMoreTapped: {
                        withAnimation(.easeInOut) {
                            _ = store.send(.moreButtonTapped)
                        }
                    }
                )
                
                if store.participantRole == .landlord {
                    Rectangle()
                        .fill(.lineAlternative)
                        .frame(height: 1)
                }
                
                if store.showsApplicationBanner {
                    ChatApplicationBanner {
                        store.send(.applicationBannerTapped)
                    }
                }
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            let dateText = store.chatRoom.localizedDateText(language: AppLanguage(locale: locale))
                            
                            if !dateText.isEmpty {
                                Text(dateText)
                                    .kohereTextStyle(.body3Regular)
                                    .foregroundColor(.neutral40)
                            }
                            
                            initialContent
                            
                            ForEach(store.messages) { message in
                                ChatMessageRow(message: message, participantRole: store.participantRole)
                                    .padding(.horizontal, 20)
                            }
                            
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 1)
                        .overlay(alignment: .bottom) {
                            Color.clear
                                .frame(height: 1)
                                .id(ChatScrollAnchor.bottom)
                        }
                    }
                    .background(.white)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { dismissKeyboard() }
                    )
                    .onChange(of: store.messages.count) {
                        scrollToLatestMessage(using: proxy)
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    ) { _ in
                        scrollToLatestMessage(using: proxy)
                    }
                }
                
                ChatComposer(showsKeywords: store.showsKeywordSuggestions, messageText: store.messageText,
                             onTextChanged: { store.send(.messageTextChanged($0)) },
                             onKeywordTapped: { store.send(.keywordTapped($0)) },
                             onSendTapped: { store.send(.sendButtonTapped) })
            }
            
            if store.isMoreMenuPresented {
                Color("materialDimmer")
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            _ = store.send(.moreMenuDismissed)
                        }
                    }
                    .transition(.opacity)
                
                ChatMoreMenu { action in
                    withAnimation(.easeInOut) {
                        _ = store.send(.moreMenuActionTapped(action))
                    }
                }
                .padding(.top, 52)
                .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundNormalNormal)
        .onAppear {
            store.send(.onAppear)
        }
        .interactivePopGestureEnabled()
    }
}

private extension ChatDetailView {
    enum ChatScrollAnchor {
        case bottom
    }
    
    func scrollToLatestMessage(using proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
            }
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @ViewBuilder var initialContent: some View {
        switch store.participantRole {
        case .tenant:
            ChatTenantInitialContent(item: store.chatRoom, hasSubmittedApplication: store.hasSubmittedApplication,
                                     onDetailsTapped: { store.send(.viewDetailsButtonTapped) })
            
        case .landlord:
            ChatLandlordInitialContent(item: store.chatRoom)
        }
    }
}
