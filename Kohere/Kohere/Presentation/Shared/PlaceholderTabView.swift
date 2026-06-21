//
//  PlaceholderTabView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import SwiftUI

struct PlaceholderTabView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.backgroundNormalAlternative
                .ignoresSafeArea()

            Text(title)
                .kohereTextStyle(.heading1Bold)
                .foregroundStyle(Color.labelNormal)
        }
    }
}
