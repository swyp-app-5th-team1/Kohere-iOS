//
//  ChatFailedMessageBottomSheet.swift
//  Kohere
//
//  Created by soomin on 9/2/26.
//

import SwiftUI

struct ChatFailedMessageBottomSheet: View {

    // MARK: - Properties

    let onResendTapped: () -> Void
    let onDeleteTapped: () -> Void
    let onCancelTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            actionCard
            cancelButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Subviews

    private var actionCard: some View {
        VStack(spacing: 0) {
            Text("chat.failedMessage.dialog.title")
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelNeutral)
                .frame(maxWidth: .infinity)
                .frame(height: 48)

            Rectangle()
                .fill(.lineNormal)
                .frame(height: 1)

            actionButton(title: "chat.failedMessage.action.resend", color: .statusBlue50, action: onResendTapped)

            Rectangle()
                .fill(.lineNormal)
                .frame(height: 1)

            actionButton(title: "chat.failedMessage.action.delete", color: .statusRed50, action: onDeleteTapped)
        }
        .background(.backgroundNormalNormal)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.neutral10, lineWidth: 1)
        }
    }

    private var cancelButton: some View {
        Button(action: onCancelTapped) {
            Text("common.cancel")
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.staticWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.neutral10)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    private func actionButton(title: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
