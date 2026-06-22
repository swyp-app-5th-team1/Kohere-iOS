//
//  EmailVerificationStepView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import SwiftUI

struct EmailVerificationStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Verify your email\nand you're all set")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("E-mail")
                    .font(.system(size: 14, weight: .semibold))
                
                HStack(spacing: 8) {
                    OnboardingTextField(
                        text: $store.email,
                        activeField: $activeField,
                        keyboardField: $keyboardField,
                        equals: .email,
                        placeholder: "Enter your email"
                    )
                    .disabled(store.isEmailVerified)
                    
                    Button {
                        store.send(.sendVerificationCodeTapped)
                    } label: {
                        Text(store.isEmailVerified ? "Verified" : (store.isCodeSent ? "Resend" : "Verify"))
                            .kohereTextStyle(.label2Medium)
                            .foregroundColor(store.isEmailVerified ? .labelAssistive : (store.email.isEmpty ? .labelAssistive : .labelNormal))
                            .frame(width: 80, height: 40)
                            .background(store.email.isEmpty ? .fillNormal : .fillStrong)
                            .cornerRadius(12)
                    }
                    .disabled(store.email.isEmpty || store.isEmailVerified)
                }
                
                if store.isCodeSent && !store.isEmailVerified {
                    HStack(spacing: 8) {
                        OnboardingTextField(
                            text: $store.verificationCode,
                            activeField: $activeField,
                            keyboardField: $keyboardField,
                            equals: .verificationCode,
                            placeholder: "Enter the 6-digit code"
                        )
                        .disabled(store.isEmailVerified)
                        
                        Button {
                            store.send(.confirmVerificationCodeTapped)
                        } label: {
                            Text("Confirm")
                                .kohereTextStyle(.label2Medium)
                                .foregroundColor(store.verificationCode.isEmpty ? .labelAssistive : .staticWhite)
                                .frame(width: 80, height: 40)
                                .background(store.verificationCode.isEmpty ? .fillNormal : .labelNormal)
                                .cornerRadius(12)
                        }
                        .disabled(store.verificationCode.isEmpty || store.isEmailVerified)
                    }
                }
            }
        }
    }
}
