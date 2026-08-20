//
//  KohereActionPopup.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

import SwiftUI

struct KohereActionPopup: View {
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let onPrimaryTapped: () -> Void
    let onSecondaryTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .kohereTextStyle(.body2Regular)
                .foregroundStyle(.coolNeutral70)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            HStack(spacing: 8) {
                Button {
                    onSecondaryTapped()
                } label: {
                    Text(secondaryTitle)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundStyle(.labelNormal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.fillStrong)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onPrimaryTapped()
                } label: {
                    Text(primaryTitle)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundStyle(.staticWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.primary50)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
        .frame(width: 313)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
