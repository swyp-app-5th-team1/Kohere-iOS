//
//  UserBubbleButton.swift
//  Kohere
//
//  Created by mandoo on 6/26/26.
//

import SwiftUI

struct UserBubbleButton: View {

    // MARK: - Properties

    let title: String
    let isSelected: Bool
    var fillsAvailableWidth = false
    var isDisabled = false
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundColor(isDisabled ? .labelDisable : isSelected ? .primaryNormal : .labelNeutral)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
                .background(.secondary5)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .primaryNormal : .lineAlternative, lineWidth: 1)
                )
        }
        .disabled(isDisabled)
    }
}
