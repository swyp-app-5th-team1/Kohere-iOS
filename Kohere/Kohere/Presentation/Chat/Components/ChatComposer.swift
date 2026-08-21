//
//  ChatComposer.swift
//  Kohere
//
//  Created by soomin on 8/21/26.
//

import SwiftUI

struct ChatComposer: View {
    
    // MARK: - Properties

    let showsKeywords: Bool
    let messageText: String
    let onTextChanged: (String) -> Void
    let onKeywordTapped: (String) -> Void
    let onSendTapped: () -> Void

    @FocusState private var isMessageFieldFocused: Bool

    private let keywords = [
        "chat.detail.keyword.availability",
        "chat.detail.keyword.weeklyPrice",
        "chat.detail.keyword.payment",
        "chat.detail.keyword.earlyTermination",
        "chat.detail.keyword.depositReturn"
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            if showsKeywords && !isMessageFieldFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(keywords, id: \.self) { key in
                            let keyword = String(localized: String.LocalizationValue(key))
                            Button {
                                onKeywordTapped(keyword)
                            } label: {
                                Text(keyword)
                                    .kohereTextStyle(.label3Medium)
                                    .foregroundStyle(.labelNeutral)
                                    .padding(.horizontal, 12)
                                    .frame(height: 32)
                            }
                            .buttonStyle(ChatKeywordButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)
            }

            HStack(spacing: 8) {
                TextField("", text: Binding(get: { messageText }, set: onTextChanged),
                          prompt: Text("chat.detail.messagePlaceholder")
                                    .foregroundStyle(isMessageFieldFocused ? .coolNeutral40 : .coolNeutral10))
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral70)
                    .tint(.coolNeutral30)
                    .focused($isMessageFieldFocused)

                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: onSendTapped) {
                        Image(.chatSend)
                            .renderingMode(.original)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(.common0)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inputBorderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, isMessageFieldFocused ? 16 : (showsKeywords ? 0 : 10))
        }
        .padding(.bottom, isMessageFieldFocused ? 24 : 0)
        .background(.common0)
    }
    
    // MARK: - SubView
    
    private var inputBorderColor: Color {
        if isMessageFieldFocused || !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .primary20
        }
        return .coolNeutral20
    }
}

// MARK: - Button Style

struct ChatKeywordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? .coolNeutral5 : .common0, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(configuration.isPressed ? .coolNeutral80 : .coolNeutral10, lineWidth: 1)
            )
    }
}
