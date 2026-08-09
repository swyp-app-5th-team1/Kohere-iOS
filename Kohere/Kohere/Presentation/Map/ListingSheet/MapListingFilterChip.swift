//
//  MapListingFilterChip.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapListingFilterChip: View {
    let item: MapListingFilterChipItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(verbatim: item.title)
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(foregroundStyle)

                if item.showsChevron {
                    Image(.chevronDownFill16)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.labelNeutral)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(.coolNeutral5)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(borderStyle, lineWidth: item.style == .plain ? 0 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundStyle: Color {
        switch item.style {
        case .plain, .manual:
            .labelNeutral
        case .diagnosis:
            .primaryPress
        }
    }

    private var borderStyle: Color {
        switch item.style {
        case .plain:
            .clear
        case .manual:
            .labelStrong
        case .diagnosis:
            .primaryPress
        }
    }
}
