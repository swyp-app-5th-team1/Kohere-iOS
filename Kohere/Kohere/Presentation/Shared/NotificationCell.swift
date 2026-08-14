//
//  NotificationCell.swift
//  Kohere
//
//  Created by soomin on 8/14/26.
//

import SwiftUI

struct NotificationCell: View {

    // MARK: - Properties

    let icon: ImageResource
    let category: String
    let title: String
    let time: String
    let onTap: () -> Void

    // MARK: - Initializer
    
    init(
        icon: ImageResource,
        category: String,
        title: String,
        time: String,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.category = category
        self.title = title
        self.time = time
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 4) {
                Image(icon)
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 24, height: 24)
                    .padding(.top, -4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.labelAlternative)

                    Text(title)
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(.labelNormal)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(time)
                        .kohereTextStyle(.caption2Semibold)
                        .foregroundStyle(.labelNeutral)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(NotificationCellButtonStyle())
        .padding(.horizontal, 16)
    }
}

private struct NotificationCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.backgroundNormalAlternative : Color.backgroundNormalNormal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
