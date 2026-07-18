//
//  ChatBotView.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatBotView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatBotFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) }),
                center: .text("Find My Room"),
                backgroundColor: .backgroundNormalNormal,
                height: 48
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.lineNeutral)
                    .frame(height: 1)
            }
            
            messageScrollView
            
            bottomButtonArea
        }
        .onAppear { store.send(.onAppear) }
    }
}

extension ChatBotView {
    
    // MARK: - Subviews
    
    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(store.history.enumerated()), id: \.element.id) { index, item in
                        messageRow(for: item)
                        
                        if index < store.history.count - 1 {
                            Spacer()
                                .frame(height: calculateSpacing(current: item, nextIndex: index + 1))
                        }
                    }
                    
                    if let currentDiagnosis = store.currentDiagnosis {
                        HStack {
                            Spacer()
                            
                            ChatBotOptionsView(store: store, diagnosis: currentDiagnosis)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .onChange(of: store.history.count) { _, _ in
                scrollToLastUserMessage(with: proxy)
            }
        }
        .background(
            Image(.dotBackground)
                .resizable(resizingMode: .tile)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var bottomButtonArea: some View {
        VStack(alignment: .center, spacing: 8) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
            
            HStack(spacing: 8) {
                Button {
                    store.send(.resetButtonTapped)
                } label: {
                    Image(.reset24)
                        .renderingMode(.template)
                        .foregroundColor(.labelAlternative)
                        .frame(width: 48, height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.lineNormal, lineWidth: 1)
                        }
                }
                
                Button {
                    store.send(.findButtonTapped)
                } label: {
                    Text(String(localized: "chatBot.action.find"))
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(store.isFindButtonEnabled ? .staticWhite : .labelDisable)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(store.isFindButtonEnabled ? .labelNormal : .fillNormal)
                        .cornerRadius(16)
                }
                .disabled(!store.isFindButtonEnabled)
            }
            .padding(.horizontal, 20)
        }
        .background(.staticWhite)
    }
    
    // MARK: - Methods
    
    @ViewBuilder
    private func messageRow(for item: ChatBotFeature.ChatItem) -> some View {
        switch item {
        case let .bot(_, text, isFirst):
            BotMessageRow(text: text, isFirst: isFirst)
        case let .user(_, text):
            UserMessageRow(text: text)
        }
    }
    
    private func calculateSpacing(current: ChatBotFeature.ChatItem, nextIndex: Int) -> CGFloat {
        guard nextIndex < store.history.count else { return 0 }
        let nextItem = store.history[nextIndex]
        return (isBot(current) == isBot(nextItem)) ? 4 : 20
    }
    
    private func isBot(_ item: ChatBotFeature.ChatItem) -> Bool {
        switch item {
        case .bot: return true
        case .user: return false
        }
    }
    
    private func scrollToLastUserMessage(with proxy: ScrollViewProxy) {
        if let lastUserMessage = store.history.last(where: {
            if case .user = $0 { return true }
            return false
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(lastUserMessage.id, anchor: .top)
                }
            }
        }
    }
}
