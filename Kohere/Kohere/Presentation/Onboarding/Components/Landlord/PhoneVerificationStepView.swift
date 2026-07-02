//
//  PhoneVerificationStepView.swift
//  Kohere
//
//  Created by mandoo on 7/2/26.
//

import ComposableArchitecture
import SwiftUI

struct PhoneVerificationStepView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<OnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("사장님이 맞는지\n안전하게 확인해볼게요!")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 16) {
                Text("전화번호")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.neutral90)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        OnboardingTextField(
                            text: $store.phoneNumber,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .phoneNumber,
                            placeholder: "'-'를 제외하고 숫자만 입력해주세요",
                            keyboardType: .phonePad,
                            hasError: store.hasPhoneNumberFormatError
                        )
                        .disabled(store.isPhoneVerified)

                        Button {
                            store.send(.sendPhoneVerificationCodeTapped)
                        } label: {
                            verificationButtonTitle
                        }
                        .disabled(!store.canSendPhoneVerificationCode || store.isPhoneVerified)
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
                            placeholder: "전송된 6자리 코드를 입력해주세요",
                            keyboardType: .numberPad,
                            hasError: store.phoneVerificationCodeErrorMessage != nil
                        )
                        .disabled(!store.isPhoneCodeSent || store.isPhoneVerified)

                        Button {
                            store.send(.confirmPhoneVerificationCodeTapped)
                        } label: {
                            confirmButtonTitle
                        }
                        .disabled(!store.canConfirmPhoneVerificationCode || store.isPhoneVerified)
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
        Text(store.isPhoneVerified ? "인증완료" : (store.isPhoneCodeSent ? "재발송" : "인증"))
            .kohereTextStyle(.label2Medium)
            .foregroundColor(store.canSendPhoneVerificationCode && !store.isPhoneVerified ? .labelNormal : .labelAssistive)
            .frame(width: 80, height: 40)
            .background(store.canSendPhoneVerificationCode && !store.isPhoneVerified ? .fillStrong : .fillNormal)
            .cornerRadius(12)
    }

    private var confirmButtonTitle: some View {
        Text("확인")
            .kohereTextStyle(.label2Medium)
            .foregroundColor(store.canConfirmPhoneVerificationCode && !store.isPhoneVerified ? .staticWhite : .labelAssistive)
            .frame(width: 80, height: 40)
            .background(store.canConfirmPhoneVerificationCode && !store.isPhoneVerified ? .labelNormal : .fillNormal)
            .cornerRadius(12)
    }

    @ViewBuilder private var phoneSupportText: some View {
        if store.hasPhoneNumberFormatError {
            Text("전화번호 형식에 맞지 않는 문자가 포함되어 있어요.")
                .kohereTextStyle(.caption2Medium)
                .foregroundStyle(.statusDanger)
                .padding(.leading, 8)
        } else if let phoneMessage = store.phoneMessage {
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
