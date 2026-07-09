//
//  EmailVerificationStepView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import ComposableArchitecture
import SwiftUI

struct EmailVerificationStepView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TenantOnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("Verify your email\nand you're all set")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.coolNeutral90)

            VStack(alignment: .leading, spacing: 16) {
                Text("E-mail")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.coolNeutral90)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        OnboardingTextField(
                            text: $store.email,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .email,
                            placeholder: "Enter your email",
                            keyboardType: .emailAddress,
                            hasError: store.hasEmailFormatError
                        )
                        .allowsHitTesting(!store.isEmailVerified && !store.isEmailVerificationCodeRequesting)

                        Button {
                            store.send(.sendVerificationCodeTapped)
                        } label: {
                            verificationButtonTitle
                        }
                        .disabled(!store.canSendEmailVerificationCode || store.isEmailVerified || store.isEmailVerificationCodeRequesting)
                    }

                    emailSupportText
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        OnboardingTextField(
                            text: $store.verificationCode,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .verificationCode,
                            placeholder: "Enter the 6-digit code",
                            keyboardType: .numberPad,
                            hasError: store.emailVerificationCodeErrorMessage != nil
                        )
                        .allowsHitTesting(store.isCodeSent && !store.isEmailVerified)

                        Button {
                            store.send(.confirmVerificationCodeTapped)
                        } label: {
                            confirmButtonTitle
                        }
                        .disabled(!store.canConfirmEmailVerificationCode || store.isEmailVerified || store.isEmailVerificationRequesting)
                    }

                    emailVerificationCodeSupportText
                }
            }
        }
    }
}

// MARK: - Subviews

extension EmailVerificationStepView {
    private var verificationButtonTitle: some View {
        Text(store.isEmailVerified ? "Verified" : (store.isCodeSent ? "Resend" : "Verify"))
            .kohereTextStyle(.label2Medium)
            .foregroundColor(verificationButtonTextColor)
            .frame(width: 80, height: 40)
            .background(verificationButtonBackgroundColor)
            .cornerRadius(12)
    }

    private var verificationButtonTextColor: Color {
        if store.isCodeSent && !store.isEmailVerified && !store.isEmailVerificationCodeRequesting {
            return .labelNormal
        } else if store.canSendEmailVerificationCode && !store.isEmailVerified && !store.isEmailVerificationCodeRequesting {
            return .staticWhite
        } else {
            return .labelAssistive
        }
    }

    private var verificationButtonBackgroundColor: Color {
        if store.isCodeSent && !store.isEmailVerified && !store.isEmailVerificationCodeRequesting {
            return .fillStrong
        } else if store.canSendEmailVerificationCode && !store.isEmailVerified && !store.isEmailVerificationCodeRequesting {
            return .labelNormal
        } else {
            return .fillNormal
        }
    }

    private var confirmButtonTitle: some View {
        Text("Confirm")
            .kohereTextStyle(.label2Medium)
            .foregroundColor(store.canConfirmEmailVerificationCode && !store.isEmailVerified && !store.isEmailVerificationRequesting ? .staticWhite : .labelAssistive)
            .frame(width: 80, height: 40)
            .background(store.canConfirmEmailVerificationCode && !store.isEmailVerified && !store.isEmailVerificationRequesting ? .labelNormal : .fillNormal)
            .cornerRadius(12)
    }

    @ViewBuilder private var emailSupportText: some View {
        if store.hasEmailFormatError {
            Text("Please enter a valid email address")
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusDanger)
                .padding(.leading, 8)
        } else if let emailMessage = store.emailMessage {
            Text(emailMessage)
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusInfo)
                .padding(.leading, 8)
        }
    }

    @ViewBuilder private var emailVerificationCodeSupportText: some View {
        if let emailVerificationCodeErrorMessage = store.emailVerificationCodeErrorMessage {
            Text(emailVerificationCodeErrorMessage)
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusDanger)
                .padding(.leading, 8)
        }
    }
}
