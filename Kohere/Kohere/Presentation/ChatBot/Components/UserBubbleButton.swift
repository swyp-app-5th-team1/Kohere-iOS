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
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundColor(isSelected ? .primaryNormal : .labelNeutral)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.secondary5)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .primaryNormal : .lineAlternative, lineWidth: 1)
                )
        }
    }
}
