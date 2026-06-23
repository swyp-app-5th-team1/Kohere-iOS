//
//  DropdownMenu.swift
//  DropdownMenu
//
//  Created by mandoo on 6/21/26.
//

import SwiftUI

struct DropdownMenu: View {
    
    // MARK: - Properties

    @Binding var selectedOption: DropdownMenuOption?
    @Binding var activeField: OnboardingField?
    
    var keyboardField: FocusState<OnboardingField?>.Binding
    let equals: OnboardingField
    let options: [DropdownMenuOption]
    let listHeight: CGFloat

    private var isOptionsPresented: Bool {
        activeField == equals
    }

    // MARK: - Body
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {

                keyboardField.wrappedValue = nil

                if isOptionsPresented {
                    activeField = nil
                } else {
                    activeField = equals
                }
            }
        } label: {
            HStack {
                Text(selectedOption?.option ?? "Select")
                    .kohereTextStyle(.label2Medium)
                    .foregroundColor(
                        selectedOption == nil
                        ? .labelAssistive
                        : .labelNeutral
                    )

                Spacer()

                Image(isOptionsPresented ? .chevronUp16 : .chevronDown16)
                    .renderingMode(.template)
                    .foregroundColor(.coolNeutral20)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isOptionsPresented
                    ? .labelNormal
                    : .lineAlternative,
                    lineWidth: 1
                )
        }
        .overlay(alignment: .top) {
            if isOptionsPresented {
                DropdownMenuList(
                    options: options,
                    listHeight: listHeight
                ) { option in
                    selectedOption = option
                    activeField = nil
                }
                .offset(y: 46)
                .zIndex(999)
            }
        }
    }
}
