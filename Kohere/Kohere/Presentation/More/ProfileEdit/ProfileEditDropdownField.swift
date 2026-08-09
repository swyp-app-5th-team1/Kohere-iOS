//
//  ProfileEditDropdownField.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct ProfileEditDropdownField: View {

    // MARK: - Properties

    let title: LocalizedStringResource
    @Binding var selectedOption: DropdownMenuOption?
    @Binding var activeField: ProfileEditField?
    var keyboardField: FocusState<ProfileEditField?>.Binding
    let equals: ProfileEditField
    let options: [DropdownMenuOption]
    let listHeight: CGFloat
    var isRequired = false

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
        HStack(spacing: 10) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.coolNeutral40)

            Spacer(minLength: 0)

            if isRequired {
                Text(verbatim: "*")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.statusDanger)
            }
        }
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
