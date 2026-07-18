//
//  ChatRoomRow.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import SwiftUI

struct ChatRoomRowCell: View {
    
    // MARK: - Properties
    
    let item: ChatRoomModel
    let participantRole: ChatParticipantRole
    let isRevealed: Bool
    let onTap: (Int) -> Void
    let onReveal: () -> Void
    let onClose: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    let onDelete: () -> Void

    @GestureState private var dragTranslation: CGFloat = 0

    private let actionSize: CGFloat = 70

    private var totalActionWidth: CGFloat {
        actionSize * 3
    }

    private var rowOffset: CGFloat {
        let restingOffset = isRevealed ? -totalActionWidth : 0
        return min(0, max(-totalActionWidth, restingOffset + dragTranslation))
    }
    
    private var statusText: String {
        switch participantRole {
        case .tenant:
            return String(localized: "chat.applicationSent.title")
        case .landlord:
            return String(localized: "chat.applicationReceived.title")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .trailing) {
            actionButtons

            Button {
                if isRevealed {
                    onClose()
                } else {
                    onTap(item.id)
                }
            } label: {
                rowContent
            }
            .buttonStyle(ChatRoomRowButtonStyle())
            .offset(x: rowOffset)
            .highPriorityGesture(swipeGesture)
        }
        .clipped()
        .animation(.snappy(duration: 0.25), value: isRevealed)
    }

    private var actionButtons: some View {
        HStack(spacing: 0) {
            swipeActionButton(
                imageName: "megaphone_24",
                accessibilityLabel: "채팅 신고",
                backgroundColor: .coolNeutral20,
                action: onReport
            )

            swipeActionButton(
                imageName: "circle_block_24",
                accessibilityLabel: "채팅 차단",
                backgroundColor: .coolNeutral40,
                action: onBlock
            )

            swipeActionButton(
                imageName: "delete_24",
                accessibilityLabel: "채팅 삭제",
                backgroundColor: .primaryNormal,
                action: onDelete
            )
        }
        .frame(width: totalActionWidth)
        .frame(height: actionSize)
    }

    private func swipeActionButton(
        imageName: String,
        accessibilityLabel: String,
        backgroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            onClose()
            action()
        } label: {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: actionSize, height: actionSize)
        .background(backgroundColor)
        .accessibilityLabel(accessibilityLabel)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($dragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                state = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                let restingOffset = isRevealed ? -totalActionWidth : 0
                let projectedOffset = restingOffset + value.predictedEndTranslation.width

                if projectedOffset < -(totalActionWidth / 2) {
                    onReveal()
                } else {
                    onClose()
                }
            }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(.personFill24)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .foregroundStyle(.secondary5)
                .frame(width: 24, height: 24)
                .frame(width: 36, height: 36)
                .background(.primary10)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(item.listingName)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.labelNeutral)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(item.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundColor(.neutral20)
                        .lineLimit(1)
                }
                
                Text(statusText)
                    .kohereTextStyle(.body3Regular)
                    .foregroundColor(.neutral40)
                    .lineLimit(1)
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: actionSize, maxHeight: actionSize, alignment: .leading)
    }
}

private struct ChatRoomRowButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                ? Color.backgroundNormalAlternative
                : Color.backgroundNormalNormal
            )
            .contentShape(Rectangle())
    }
}
