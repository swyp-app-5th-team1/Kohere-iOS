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
            case 0, 1, 2, 6:
                horizontalOptionsView
            case 3:
                verticalOptionsView
            case 4:
                multiSelectOptionsView
            case 5:
                budgetSliderView
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Subviews

extension ChatBotOptionsView {
    private var horizontalOptionsView: some View {
        HStack(spacing: 8) {
            ForEach(diagnosis.options, id: \.id) { option in
                UserBubbleButton(title: option.title, isSelected: false) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = store.send(.optionTapped(option))
                    }
                }
                .disabled(store.isAnswerSaving)
            }
        }
    }
    
    private var verticalOptionsView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(diagnosis.options, id: \.id) { option in
                UserBubbleButton(title: option.title, isSelected: false) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = store.send(.optionTapped(option))
                    }
                }
                .disabled(store.isAnswerSaving)
            }
        }
    }
    
    private var multiSelectOptionsView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(diagnosis.options.prefix(3), id: \.id) { option in
                    UserBubbleButton(
                        title: option.title,
                        isSelected: store.selectedOptionCodes.contains(option.id)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                    .disabled(store.isAnswerSaving)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(diagnosis.options.dropFirst(3).prefix(2), id: \.id) { option in
                    UserBubbleButton(
                        title: option.title,
                        isSelected: store.selectedOptionCodes.contains(option.id)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                    .disabled(store.isAnswerSaving)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(diagnosis.options.dropFirst(5).prefix(3), id: \.id) { option in
                    UserBubbleButton(
                        title: option.title,
                        isSelected: store.selectedOptionCodes.contains(option.id)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                    .disabled(store.isAnswerSaving)
                }
            }
            confirmButton
        }
    }

    private var budgetSliderView: some View {
        VStack(alignment: .trailing, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("월세")
                        .kohereTextStyle(.label2Medium)
                        .foregroundStyle(.labelNeutral)

                    Spacer(minLength: 0)

                    Text(store.budgetSummaryText)
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.primary100)
                }

                VStack(spacing: 6) {
                    RangeSlider(
                        value: store.budgetRange,
                        bounds: MapFilterPriceRange.monthlyRent,
                        onMinimumChange: { store.send(.budgetMinimumChanged($0)) },
                        onMaximumChange: { store.send(.budgetMaximumChanged($0)) }
                    )
                    .frame(height: 24)

                    HStack {
                        Text("0")
                            .frame(width: 46, alignment: .leading)

                        Spacer(minLength: 0)

                        Text("₩500K")
                            .frame(width: 46, alignment: .center)

                        Spacer(minLength: 0)

                        Text("₩1M")
                            .frame(width: 46, alignment: .trailing)
                    }
                    .kohereTextStyle(.caption2Regular)
                    .foregroundStyle(.labelAlternative)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 291)
            .background(.secondary5)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.lineAlternative, lineWidth: 1)
            )

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = store.send(.budgetConfirmButtonTapped)
                }
            } label: {
                Text("confirm")
                    .kohereTextStyle(.label2Medium)
                    .underline()
                    .foregroundColor(.statusRed50)
                    .padding(.trailing, 2)
            }
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
        .disabled(!store.isConfirmButtonEnabled || store.isAnswerSaving)
    }
}
