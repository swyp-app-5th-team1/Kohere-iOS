//
//  MapFilterSelectionChip.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapFilterSelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label3Medium)
                .foregroundStyle(isSelected ? .primaryNormal : .labelNeutral)
                .padding(.horizontal, 12)
                .frame(minWidth: 52)
                .frame(height: 32)
                .background(.coolNeutral5)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? Color.primaryPress : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
