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
    let keyboardType: UIKeyboardType
    let hasError: Bool

    init(
        text: Binding<String>,
        activeField: Binding<OnboardingField?>,
        keyboardField: FocusState<OnboardingField?>.Binding,
        equals: OnboardingField,
        placeholder: String?,
        keyboardType: UIKeyboardType = .default,
        hasError: Bool = false
    ) {
        self._text = text
        self._activeField = activeField
        self.keyboardField = keyboardField
        self.equals = equals
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.hasError = hasError
    }

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
                .keyboardType(keyboardType)
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
                    borderColor,
                    lineWidth: 1
                )
        }
    }

    private var borderColor: Color {
        if hasError {
            return .statusDanger
        } else if isActive {
            return .labelNormal
        } else {
            return .lineAlternative
        }
    }
}
