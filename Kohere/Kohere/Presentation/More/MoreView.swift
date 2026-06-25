//
//  MoreView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MoreView: View {
    let store: StoreOf<MoreFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileCard
                    .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    MoreMenuSection(
                        title: "내 활동",
                        items: [
                            .init(title: "Saved Listings", iconName: "heart_24"),
                            .init(title: "Recently viewed", iconName: "thunder_24"),
                            .init(title: "My Posts", iconName: "pencil_24")
                        ],
                        horizontalPadding: 16
                    )

                    MoreMenuSection(
                        title: "Korea Living Guide",
                        items: [
                            .init(title: "Korean Contract Checklist", iconName: "contractChecklist", rendersAsTemplate: false),
                            .init(title: "Bank Account Guide", iconName: "bankAccountGuide", rendersAsTemplate: false),
                            .init(title: "Top 3 Seoul Subway Apps", iconName: "train", rendersAsTemplate: false),
                            .init(title: "Health Insurance Guide", iconName: "healthInsurance", rendersAsTemplate: false)
                        ],
                        horizontalPadding: 16
                    )

                    MoreMenuSection(
                        title: "사장님 서비스",
                        items: [
                            .init(
                                title: "무료로 방 홍보하기",
                                subtitle: "고시원 · 쉐어하우스 · 코리빙 등",
                                iconName: "external_link_24"
                            )
                        ],
                        horizontalPadding: 16
                    )

                    MoreMenuSection(
                        title: "Customer Support",
                        items: [
                            .init(title: "Announcements", iconName: "megaphone_24"),
                            .init(title: "Send Feedback", iconName: "mail_24"),
                            .init(title: "Partner With Kohere", iconName: "send_24")
                        ],
                        horizontalPadding: 16
                    )
                }
                .padding(16)
                .background(Color.neutral5)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(Color.backgroundNormalAlternative)
    }

    private var profileCard: some View {
        Button {
        } label: {
            ZStack {
                Image("profileBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.secondary5)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image("person_24")
                                .renderingMode(.template)
                                .foregroundStyle(Color.primary50)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.secondary5, lineWidth: 1.5)
                        )

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Nickname")
                            .kohereTextStyle(.label1Medium)
                            .foregroundStyle(Color.neutral5)

                        Text("@user_code")
                            .kohereTextStyle(.caption2Regular)
                            .foregroundStyle(Color.primary5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("pencil_write_24")
                        .renderingMode(.template)
                        .foregroundStyle(Color.staticWhite)
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 76)
        }
        .buttonStyle(.plain)
    }
}

private struct MoreMenuSection: View {
    let title: String
    let items: [MoreMenuItem]
    let horizontalPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(Color.neutral30)
                .frame(height: 28, alignment: .center)

            VStack(spacing: 4) {
                ForEach(items) { item in
                    MoreMenuRow(item: item)
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.staticWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MoreMenuRow: View {
    let item: MoreMenuItem

    var body: some View {
        Button {
        } label: {
            HStack {
                HStack(spacing: 4) {
                    if let iconName = item.iconName {
                        Image(iconName)
                            .renderingMode(item.rendersAsTemplate ? .template : .original)
                            .resizable()
                            .foregroundStyle(Color.coolNeutral40)
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .kohereTextStyle(.label2Medium)
                            .foregroundStyle(Color.neutral80)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .kohereTextStyle(.label3Medium)
                                .foregroundStyle(Color.neutral50)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image("chevron_right_16")
                    .renderingMode(.template)
                    .foregroundStyle(Color.coolNeutral40)
                    .frame(width: 16, height: 16)
            }
            .contentShape(Rectangle())
            .frame(height: item.subtitle == nil ? 40 : 48)
        }
        .buttonStyle(.plain)
    }
}

private struct MoreMenuItem: Identifiable, Equatable {
    let title: String
    var subtitle: String?
    let iconName: String?
    var rendersAsTemplate = true

    var id: String { title }
}
