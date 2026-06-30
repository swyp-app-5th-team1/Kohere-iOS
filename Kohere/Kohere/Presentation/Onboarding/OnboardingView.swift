//
//  OnboardingView.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<OnboardingFeature>
    @State private var activeField: OnboardingField?
    @FocusState private var keyboardField: OnboardingField?
    
    // MARK: - Body
    
    var body: some View {
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
                case .emailVerification:
                    EmailVerificationStepView(store: store, activeField: $activeField, keyboardField: $keyboardField)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            bottomButtonArea
                .padding(.horizontal, 20)
        }
        .background(.backgroundNormalAlternative)
    }
}

// MARK: - Subviews

extension OnboardingView {
    private var topProgressBar: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { index in
                Rectangle()
                    .fill(store.currentStep.rawValue >= index ? .labelNormal : .fillStrong)
                    .frame(height: 2)
            }
        }
    }
    
    private var bottomButtonArea: some View {
        HStack(spacing: 8) {
            if store.currentStep > .nameAndBirth {
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
                if store.currentStep == .emailVerification {
                    store.send(.onboardingCompleted)
                } else {
                    store.send(.nextButtonTapped)
                }
            } label: {
                Text(store.currentStep == .emailVerification ? "Get Started" : "Next")
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
