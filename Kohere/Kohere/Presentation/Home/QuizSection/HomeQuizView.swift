//
//  HomeQuizView.swift
//  Kohere
//
//  Created by soomin on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeQuizView: View {
    
    // MARK: - Property
    
    let store: StoreOf<HomeQuizFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.homeQuizTitle)
                .kohereTextStyle(.heading3Semibold)
                .foregroundColor(.coolNeutral90)
                .padding(.leading, 8)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(verbatim: "Q. \(store.quiz.question)")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundColor(.labelNormal)
                    .lineSpacing(4)
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 8) {
                    ForEach(store.quiz.choices.indices, id: \.self) { index in
                        let choice = store.quiz.choices[index]
                        let style = optionStyle(for: choice.key)
                        
                        Button {
                            store.send(.optionTapped(index: index))
                        } label: {
                            HStack(spacing: 8) {
                                Text(choice.text)
                                    .kohereTextStyle(.label2Semibold)
                                    .foregroundColor(style.textColor)
                                
                                Spacer()
                                
                                if let iconName = style.iconName {
                                    Image(iconName)
                                        .renderingMode(.template)
                                        .foregroundColor(style.textColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(style.backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(style.tintColor, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .disabled(!store.isLoaded || store.hasAnswered || store.isAnswerSubmitting)
                    }
                }

                if store.shouldShowExplanation {
                    explanationView
                }
            }
            .padding(20)
            .padding(.bottom, 8)
            .background(.backgroundNormalAlternative)
            .cornerRadius(16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
    }

    private var explanationView: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(.circleInfo24)
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(.labelNeutral)

            Text(store.explanation ?? "")
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelNeutral)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionStyle(for choiceKey: String) -> OptionStyle {
        guard let selectedChoiceKey = store.selectedChoiceKey,
              let correctChoiceKey = store.correctChoiceKey
        else {
            return .default
        }

        if choiceKey == correctChoiceKey {
            return OptionStyle(
                textColor: .statusGreen70,
                tintColor: .statusPositive,
                backgroundColor: .statusGreen5,
                iconName: "check_16"
            )
        }

        if choiceKey == selectedChoiceKey {
            return OptionStyle(
                textColor: .statusDanger,
                tintColor: .statusDanger,
                backgroundColor: .statusRed5,
                iconName: "close_16"
            )
        }

        return .default
    }

    private struct OptionStyle {
        let textColor: Color
        let tintColor: Color
        let backgroundColor: Color
        let iconName: String?

        static let `default` = OptionStyle(
            textColor: .labelNeutral,
            tintColor: .clear,
            backgroundColor: .backgroundNormalNormal,
            iconName: nil
        )
    }
}
