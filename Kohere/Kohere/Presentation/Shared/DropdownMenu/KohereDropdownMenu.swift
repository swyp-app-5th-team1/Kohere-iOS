//
//  KohereDropdownMenu.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct KohereDropdownMenu<Field: Hashable>: View {
    @Environment(\.locale)
    private var locale

    // MARK: - Properties

    @Binding var selectedOption: DropdownMenuOption?
    @Binding var activeField: Field?

    let equals: Field
    let options: [DropdownMenuOption]
    let listHeight: CGFloat
    var backgroundColor: Color = .backgroundNormalNormal
    var onExpand: (() -> Void)?

    private var isOptionsPresented: Bool {
        activeField == equals
    }

    // MARK: - Body

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isOptionsPresented {
                    activeField = nil
                } else {
                    onExpand?()
                    activeField = equals
                }
            }
        } label: {
            HStack {
                Text(
                    selectedOption?.localizedTitle(locale: locale)
                        ?? AppLanguage(locale: locale).localized("common.select")
                )
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
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                KohereDropdownMenuList(
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
