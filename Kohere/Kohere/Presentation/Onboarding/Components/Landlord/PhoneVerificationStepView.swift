//
//  PhoneVerificationStepView.swift
//  Kohere
//
//  Created by soomin on 7/2/26.
//

import ComposableArchitecture
import SwiftUI

struct PhoneVerificationStepView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<LandlordOnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text(.onboardingLandlordPhoneVerificationTitle)
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.coolNeutral90)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 16) {
                Text(.onboardingProfilePhoneNumber)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.coolNeutral90)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        OnboardingTextField(text: $store.phoneNumber, activeField: $activeField, keyboardField: keyboardField,
                                            equals: .phoneNumber,
                                            placeholder: store.appLanguage.localized(
                                                .onboardingProfilePhoneNumberPlaceholder
                                            ),
                                            keyboardType: .phonePad)
                        .allowsHitTesting(!store.isPhoneVerified && !store.isPhoneVerificationCodeRequesting)

                        Button {
                            store.send(.sendPhoneVerificationCodeTapped)
                        } label: {
                            verificationButtonTitle
                        }
                        .disabled(!store.canSendPhoneVerificationCode || store.isPhoneVerified || store.isPhoneVerificationCodeRequesting)
                    }

                    phoneSupportText
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        OnboardingTextField(
                            text: $store.phoneVerificationCode,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .phoneVerificationCode,
                            placeholder: store.appLanguage.localized(
                                .onboardingPhoneVerificationCodePlaceholder
                            ),
                            keyboardType: .numberPad,
                            hasError: store.phoneVerificationCodeErrorMessage != nil
                        )
                        .allowsHitTesting(store.isPhoneCodeSent && !store.isPhoneVerified)

                        Button {
                            store.send(.confirmPhoneVerificationCodeTapped)
                        } label: {
                            confirmButtonTitle
                        }
                        .disabled(!store.canConfirmPhoneVerificationCode || store.isPhoneVerified || store.isPhoneVerificationRequesting)
                    }

                    phoneVerificationCodeSupportText
                }
            }
        }
    }
}

// MARK: - Subviews

extension PhoneVerificationStepView {
    private var verificationButtonTitle: some View {
        Text(
            store.isPhoneVerified
                ? .onboardingPhoneVerificationVerified
                : (store.isPhoneCodeSent ? .onboardingPhoneVerificationResend : .onboardingPhoneVerificationVerify)
        )
            .kohereTextStyle(.label2Medium)
            .foregroundColor(store.canSendPhoneVerificationCode && !store.isPhoneVerified && !store.isPhoneVerificationCodeRequesting ? .labelNormal : .labelAssistive)
            .frame(width: 80, height: 40)
            .background(store.canSendPhoneVerificationCode && !store.isPhoneVerified && !store.isPhoneVerificationCodeRequesting ? .fillStrong : .fillNormal)
            .cornerRadius(12)
    }

    private var confirmButtonTitle: some View {
        Text(.commonConfirm)
            .kohereTextStyle(.label2Medium)
            .foregroundColor(store.canConfirmPhoneVerificationCode && !store.isPhoneVerified && !store.isPhoneVerificationRequesting ? .staticWhite : .labelAssistive)
            .frame(width: 80, height: 40)
            .background(store.canConfirmPhoneVerificationCode && !store.isPhoneVerified && !store.isPhoneVerificationRequesting ? .labelNormal : .fillNormal)
            .cornerRadius(12)
    }

    @ViewBuilder private var phoneSupportText: some View {
        if let phoneMessage = store.phoneMessage {
            Text(phoneMessage)
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusInfo)
                .padding(.leading, 8)
        }
    }

    @ViewBuilder private var phoneVerificationCodeSupportText: some View {
        if let phoneVerificationCodeErrorMessage = store.phoneVerificationCodeErrorMessage {
            Text(phoneVerificationCodeErrorMessage)
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusDanger)
                .padding(.leading, 8)
        }
    }
}
