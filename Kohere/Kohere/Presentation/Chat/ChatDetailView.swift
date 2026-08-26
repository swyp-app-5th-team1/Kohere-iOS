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
                            ForEach(Array(store.messages.enumerated()), id: \.element.id) { index, message in
                                VStack(spacing: 12) {
                                    if shouldShowDate(at: index), let sentAt = message.sentAt {
                                        Text(localizedDateText(sentAt))
                                            .kohereTextStyle(.body3Regular)
                                            .foregroundColor(.neutral40)
                                    }

                                    ChatMessageRow(message: message, participantRole: store.participantRole,
                                                   onBookingCardTapped: { store.send(.viewDetailsButtonTapped) })
                                }
                                    .padding(.horizontal, 20)
                                    .onAppear {
                                        if message.id == store.messages.first?.id {
                                            store.send(.loadPreviousMessages)
                                        }
                                    }
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

    func shouldShowDate(at index: Int) -> Bool {
        guard let date = store.messages[index].sentAt else { return false }
        guard index > 0, let previousDate = store.messages[index - 1].sentAt else { return true }
        return !Calendar.current.isDate(date, inSameDayAs: previousDate)
    }

    func localizedDateText(_ date: Date) -> String {
        let language = AppLanguage(locale: locale)
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = language == .korean ? "yyyy.M.d E" : "M/d/yyyy EEE"
        return formatter.string(from: date)
    }
}
