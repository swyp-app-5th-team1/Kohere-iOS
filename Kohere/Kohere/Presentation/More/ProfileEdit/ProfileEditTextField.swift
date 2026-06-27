//
//  ProfileEditTextField.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct ProfileEditTextField: View {

    // MARK: - Properties

    let title: String
    @Binding var text: String
    @Binding var activeField: ProfileEditField?
    var keyboardField: FocusState<ProfileEditField?>.Binding
    let equals: ProfileEditField
    var isRequired = false
    var characterLimit: Int?
    var keyboardType: UIKeyboardType = .default

    private var isFocused: Bool {
        activeField == equals
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleRow
            inputContainer
        }
    }
}

// MARK: - Subviews

private extension ProfileEditTextField {
    var titleRow: some View {
        HStack(spacing: 10) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.coolNeutral40)

            Spacer(minLength: 0)

            if isRequired {
                Text("*")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.statusDanger)
            }
        }
        .padding(.horizontal, 4)
    }

    var inputContainer: some View {
        HStack(spacing: 8) {
            textField
            characterCountText
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(.backgroundNormalNormal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? .primary20 : .clear, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activeField = equals
            keyboardField.wrappedValue = equals
        }
    }

    var textField: some View {
        TextField("", text: $text)
            .kohereTextStyle(.label2Medium)
            .foregroundStyle(.coolNeutral70)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused(keyboardField, equals: equals)
            .onChange(of: keyboardField.wrappedValue) { _, newValue in
                updateActiveField(newValue)
            }
            .onChange(of: text) { _, newValue in
                limitTextIfNeeded(newValue)
            }
    }

    @ViewBuilder var characterCountText: some View {
        if let characterLimit {
            Text("\(text.count)/\(characterLimit)")
        }
    }

    func updateActiveField(_ focusedField: ProfileEditField?) {
        if focusedField == equals {
            activeField = equals
        } else if activeField == equals {
            activeField = nil
        }
    }

    func limitTextIfNeeded(_ newValue: String) {
        guard let characterLimit, newValue.count > characterLimit else { return }
        text = String(newValue.prefix(characterLimit))
    }
}
