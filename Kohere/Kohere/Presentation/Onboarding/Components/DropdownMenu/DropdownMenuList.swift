//
//  DropdownMenuList.swift
//  Kohere
//
//  Created by mandoo on 6/22/26.
//

import SwiftUI

struct DropdownMenuList: View {

    // MARK: - Properties

    let options: [DropdownMenuOption]
    let listHeight: CGFloat
    let onSelectedAction: (_ option: DropdownMenuOption) -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(options) { option in
                    DropdownMenuListRow(
                        option: option,
                        onSelectedAction: onSelectedAction
                    )
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
        .frame(height: listHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.labelNormal, lineWidth: 1)
        }
    }
}

// MARK: - Row Subview

struct DropdownMenuListRow: View {

    // MARK: - Properties

    let option: DropdownMenuOption
    let onSelectedAction: (_ option: DropdownMenuOption) -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onSelectedAction(option)
        } label: {
            Text(option.option)
                .kohereTextStyle(.body3Regular)
                .foregroundColor(.labelNormal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
    }
}
