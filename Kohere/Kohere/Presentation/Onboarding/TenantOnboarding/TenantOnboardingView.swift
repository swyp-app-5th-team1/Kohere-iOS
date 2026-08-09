//
//  TenantOnboardingView.swift
//  Kohere
//
//  Created by soomin on 7/4/26.
//

import ComposableArchitecture
import SwiftUI

struct TenantOnboardingView: View {

    // MARK: - Properties

    @Environment(\.locale)
    private var locale
    @Bindable var store: StoreOf<TenantOnboardingFeature>
    @State private var activeField: OnboardingField?
    @FocusState private var keyboardField: OnboardingField?

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.backgroundNormalAlternative
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(spacing: 0) {
                topProgressBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                VStack(alignment: .leading, spacing: 0) {
                    switch store.currentStep {
                    case .nameAndBirth:
                        NameAndBirthStepView(store: store, activeField: $activeField, keyboardField: $keyboardField)
                    case .details:
                        DetailsStepView(store: store, activeField: $activeField, keyboardField: $keyboardField)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                bottomButtonArea
                    .padding(.horizontal, 20)
            }
        }
        .environment(\.locale, AppLanguage.english.locale)
    }
}

// MARK: - Subviews

private extension TenantOnboardingView {
    func dismissKeyboard() {
        activeField = nil
        keyboardField = nil
    }

    var topProgressBar: some View {
        HStack(spacing: 8) {
            ForEach(1...store.totalStepCount, id: \.self) { index in
                Rectangle()
                    .fill(store.currentStep.progressIndex == index ? .labelNormal : .fillStrong)
                    .frame(height: 2)
            }
        }
    }

    var bottomButtonArea: some View {
        HStack(spacing: 8) {
            if store.currentStep.progressIndex > 1 {
                Button {
                    store.send(.backButtonTapped)
                } label: {
                    Image(.arrowLeft24)
                        .foregroundColor(.labelAlternative)
                        .frame(width: 48, height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.lineNormal, lineWidth: 1)
                        }
                }
            }

            Button {
                if store.currentStep == .details {
                    store.send(.onboardingCompleted)
                } else {
                    store.send(.nextButtonTapped)
                }
            } label: {
                Text(
                    verbatim: store.isOnboardingSubmitting
                        ? AppLanguage(locale: locale).localized(.commonLoading)
                        : store.primaryButtonTitle
                )
                    .kohereTextStyle(.label1Semibold)
                    .foregroundColor(.staticWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(store.isNextButtonEnabled ? .primaryNormal : .primary10)
                    .cornerRadius(16)
            }
            .disabled(!store.isNextButtonEnabled)
        }
    }
}
