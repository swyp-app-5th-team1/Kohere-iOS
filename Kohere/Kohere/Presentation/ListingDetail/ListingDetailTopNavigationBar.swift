//
//  ListingDetailTopNavigationBar.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailTopNavigationBar: View {
    let progress: CGFloat
    let height: CGFloat
    let onBackTap: () -> Void
    let onShareTap: () -> Void

    var body: some View {
        HStack {
            chromeButton(imageName: "chevron_left_24", action: onBackTap)

            Spacer()

            chromeButton(imageName: "share_ios_24", action: onShareTap)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(.common0.opacity(progress))
    }

    private func chromeButton(
        imageName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.common0)
                    .opacity(1 - progress)

                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.labelAlternative)
                    .opacity(progress)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}
