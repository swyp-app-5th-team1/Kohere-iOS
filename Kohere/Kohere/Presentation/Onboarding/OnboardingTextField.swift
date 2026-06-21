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
    @FocusState private var isFocused: Bool
    
    let placeholder: String?
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            TextField("", text: $text, prompt: Text(placeholder ?? ""))
                .kohereTextStyle(.label2Medium)
                .foregroundColor(.labelNeutral)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($isFocused)
            
            if !text.isEmpty {
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
        .padding(.horizontal, 16)
        .frame(height: 40)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? .labelNormal : .lineAlternative, lineWidth: 1)
        }
    }
}
