//
//  ChatBotOptionsView.swift
//  Kohere
//
//  Created by mandoo on 6/27/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatBotOptionsView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<ChatBotFeature>
    let diagnosis: Diagnosis
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch diagnosis.step {
            case 1, 2, 5, 6:
                horizontalOptionsView
            case 3:
                verticalOptionsView
            case 4:
                multiSelectOptionsView
            default:
                EmptyView()
            }
        }
        .padding(.trailing, 20)
    }
}

// MARK: - Subviews

extension ChatBotOptionsView {
    
    private var horizontalOptionsView: some View {
        HStack(spacing: 8) {
            ForEach(diagnosis.options, id: \.code) { option in
                UserBubbleButton(title: option.label, isSelected: false) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = store.send(.optionTapped(option))
                    }
                }
            }
        }
    }
    
    private var verticalOptionsView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(diagnosis.options, id: \.code) { option in
                UserBubbleButton(title: option.label, isSelected: false) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = store.send(.optionTapped(option))
                    }
                }
            }
        }
    }
    
    private var multiSelectOptionsView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(diagnosis.options.prefix(3), id: \.code) { option in
                    UserBubbleButton(
                        title: option.label,
                        isSelected: store.selectedOptionCodes.contains(option.code)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                ForEach(diagnosis.options.dropFirst(3).prefix(2), id: \.code) { option in
                    UserBubbleButton(
                        title: option.label,
                        isSelected: store.selectedOptionCodes.contains(option.code)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                ForEach(diagnosis.options.dropFirst(5).prefix(3), id: \.code) { option in
                    UserBubbleButton(
                        title: option.label,
                        isSelected: store.selectedOptionCodes.contains(option.code)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                }
            }
            
            confirmButton
        }
    }
    
    private var confirmButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = store.send(.confirmButtonTapped)
            }
        } label: {
            Text("confirm")
                .kohereTextStyle(.label2Medium)
                .underline()
                .foregroundColor(store.isConfirmButtonEnabled ? .statusRed50 : .neutral20)
                .padding(.trailing, 2)
        }
        .disabled(!store.isConfirmButtonEnabled)
    }
}
