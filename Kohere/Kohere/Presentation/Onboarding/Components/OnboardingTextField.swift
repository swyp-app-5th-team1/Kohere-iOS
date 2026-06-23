//
//  OnboardingTextField.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import SwiftUI

struct OnboardingTextField: View {
    
    // MARK: - Properties
    
    @Binding var text: String
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding
    
    let equals: OnboardingField
    let placeholder: String?
    
    private var isActive: Bool {
        activeField == equals
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            TextField("", text: $text, prompt: Text(placeholder ?? ""))
                .kohereTextStyle(.label2Medium)
                .foregroundColor(.labelNeutral)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused(keyboardField, equals: equals)
                .onChange(of: keyboardField.wrappedValue) { _, newValue in
                    if newValue == equals {
                        activeField = equals
                    } else if activeField == equals {
                        activeField = nil
                    }
                }
            
            if !text.isEmpty && isActive {
                Button {
                    text = ""
                } label: {
                    Image(.circleCloseFill24)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.labelNormal)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activeField = equals
            keyboardField.wrappedValue = equals
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? .labelNormal : .lineAlternative,
                    lineWidth: 1
                )
        }
    }
}
