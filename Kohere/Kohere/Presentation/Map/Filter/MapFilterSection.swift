//
//  MapFilterSection.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapFilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.common100)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.common0)
    }
}
