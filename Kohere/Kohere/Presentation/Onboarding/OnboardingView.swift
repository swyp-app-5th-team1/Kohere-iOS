//
//  OnboardingView.swift
//  Kohere
//
//  Created by soomin on 6/21/26.
//

import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {

    // MARK: - Properties

    let store: StoreOf<OnboardingFeature>

    // MARK: - Body

    var body: some View {
        switch store.userType {
        case .tenant:
            if let tenantStore = store.scope(state: \.tenant, action: \.tenant) {
                TenantOnboardingView(store: tenantStore)
            }

        case .landlord:
            if let landlordStore = store.scope(state: \.landlord, action: \.landlord) {
                LandlordOnboardingView(store: landlordStore)
            }
        }
    }
}

struct OnboardingStepContainer<Content: View>: View {
    let currentStep: Int
    let totalStepCount: Int
    let isPrimaryEnabled: Bool
    let isSubmitting: Bool
    let primaryTitle: String
    let loadingTitle: String
    let onBack: () -> Void
    let onPrimary: () -> Void
    let onBackgroundTapped: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.backgroundNormalAlternative
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onBackgroundTapped)

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                content()
                    .padding(.horizontal, 20)

                Spacer()

                bottomButtonArea
                    .padding(.horizontal, 20)
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(1...totalStepCount, id: \.self) { index in
                Rectangle()
                    .fill(currentStep == index ? .labelNormal : .fillStrong)
                    .frame(height: 2)
            }
        }
    }

    private var bottomButtonArea: some View {
        HStack(spacing: 8) {
            if currentStep > 1 {
                Button(action: onBack) {
                    Image(.arrowLeft24)
                        .foregroundColor(.labelAlternative)
                        .frame(width: 48, height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.lineNormal, lineWidth: 1)
                        }
                }
            }

            Button(action: onPrimary) {
                Text(verbatim: isSubmitting ? loadingTitle : primaryTitle)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundColor(.staticWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isPrimaryEnabled ? .primaryNormal : .primary10)
                    .cornerRadius(16)
            }
            .disabled(!isPrimaryEnabled)
        }
    }
}
