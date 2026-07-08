//
//  KohereNoticePopup.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import SwiftUI

struct KohereNoticePopup: View {
    let message: String
    var confirmTitle = "확인"
    let onConfirmTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .kohereTextStyle(.body2Regular)
                .foregroundStyle(.coolNeutral70)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onConfirmTapped()
            } label: {
                Text(confirmTitle)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.fillStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: 313)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.lineAlternative, lineWidth: 1)
        }
    }
}
