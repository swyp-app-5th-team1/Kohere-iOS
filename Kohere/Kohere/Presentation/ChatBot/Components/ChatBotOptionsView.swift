//
//  ChatBotOptionsView.swift
//  Kohere
//
//  Created by mandoo on 6/27/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct ChatBotOptionsView: View {

    // MARK: - Properties

    let store: StoreOf<ChatBotFeature>
    let diagnosis: Diagnosis
    @Environment(\.locale)
    private var locale

    private let multiSelectColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

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
            LazyVGrid(columns: multiSelectColumns, alignment: .trailing, spacing: 8) {
                ForEach(diagnosis.options, id: \.id) { option in
                    UserBubbleButton(
                        title: option.title,
                        isSelected: store.selectedOptionCodes.contains(option.id),
                        fillsAvailableWidth: true
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = store.send(.optionTapped(option))
                        }
                    }
                    .disabled(store.isAnswerSaving)
                }
            }
            .frame(maxWidth: 352)

            confirmButton
        }
    }

    private var budgetSliderView: some View {
        VStack(alignment: .trailing, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localized("map.filter.monthlyRent"))
                        .kohereTextStyle(.label2Medium)
                        .foregroundStyle(.labelNeutral)

                    Spacer(minLength: 0)

                    Text(budgetSummaryText)
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
            .disabled(store.isAnswerSaving)
        }
    }

    private var budgetSummaryText: String {
        let bounds = MapFilterPriceRange.monthlyRent
        let range = store.budgetRange

        switch (range.minimum, range.maximum) {
        case (bounds.lowerBound, bounds.upperBound):
            return localized("chatBot.budget.any")

        case (bounds.lowerBound, let maximum):
            return localized(
                "chatBot.budget.under",
                arguments: [ChatBotFeature.State.budgetPriceText(maximum)]
            )

        case (let minimum, bounds.upperBound):
            return localized(
                "chatBot.budget.upperOnly",
                arguments: [ChatBotFeature.State.budgetPriceText(minimum)]
            )

        case let (minimum, maximum):
            return localized(
                "chatBot.budget.range",
                arguments: [
                    ChatBotFeature.State.budgetPriceText(minimum),
                    ChatBotFeature.State.budgetPriceText(maximum)
                ]
            )
        }
    }

    private func localized(_ key: String, arguments: [String] = []) -> String {
        let format = AppLanguage(locale: locale).localized(key)
        return String(format: format, arguments: arguments.map { $0 as CVarArg })
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
