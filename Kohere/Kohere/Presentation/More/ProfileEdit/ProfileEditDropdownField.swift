//
//  ProfileEditDropdownField.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct ProfileEditDropdownField: View {

    // MARK: - Properties

    let title: String
    @Binding var selectedOption: DropdownMenuOption?
    @Binding var activeField: ProfileEditField?
    var keyboardField: FocusState<ProfileEditField?>.Binding
    let equals: ProfileEditField
    let options: [DropdownMenuOption]
    let listHeight: CGFloat

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText
            dropdownMenu
        }
    }
}

// MARK: - Subviews

private extension ProfileEditDropdownField {
    var titleText: some View {
        Text(title)
            .kohereTextStyle(.label2Semibold)
            .foregroundStyle(Color.coolNeutral40)
            .padding(.horizontal, 4)
    }

    var dropdownMenu: some View {
        KohereDropdownMenu(
            selectedOption: $selectedOption,
            activeField: $activeField,
            equals: equals,
            options: options,
            listHeight: listHeight,
            backgroundColor: .backgroundNormalNormal,
            onExpand: {
                keyboardField.wrappedValue = nil
            }
        )
    }
}
