//
//  LandlordOnboardingView.swift
//  Kohere
//
//  Created by soomin on 7/4/26.
//

import ComposableArchitecture
import SwiftUI

struct LandlordOnboardingView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<LandlordOnboardingFeature>
    @State private var activeField: OnboardingField?
    @FocusState private var keyboardField: OnboardingField?

    // MARK: - Body

    var body: some View {
        OnboardingStepContainer(
            currentStep: store.currentStep.progressIndex,
            totalStepCount: store.totalStepCount,
            isPrimaryEnabled: store.isNextButtonEnabled,
            isSubmitting: store.isOnboardingSubmitting,
            primaryTitle: store.primaryButtonTitle,
            loadingTitle: store.appLanguage.localized(.commonLoading),
            onBack: { store.send(.backButtonTapped) },
            onPrimary: {
                store.send(store.currentStep == .phoneVerification ? .onboardingCompleted : .nextButtonTapped)
            },
            onBackgroundTapped: dismissKeyboard,
            content: {
                VStack(alignment: .leading, spacing: 0) {
                    switch store.currentStep {
                    case .nameAndBirth:
                        LandlordNameAndBirthStepView(store: store, activeField: $activeField, keyboardField: $keyboardField)
                    case .phoneVerification:
                        PhoneVerificationStepView(store: store, activeField: $activeField, keyboardField: $keyboardField)
                    }
                }
            }
        )
        .environment(\.locale, store.appLanguage.locale)
    }
}

// MARK: - Subviews

private extension LandlordOnboardingView {
    func dismissKeyboard() {
        activeField = nil
        keyboardField = nil
    }

}
