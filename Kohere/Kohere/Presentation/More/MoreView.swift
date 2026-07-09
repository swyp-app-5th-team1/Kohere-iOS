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
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .smallLogo,
                center: .text("More"),
                right: .moreTab(
                    showsLanguage: store.userType != .landlord,
                    onLanguage: { store.send(.navigationLanguageTapped) },
                    onSetting: { store.send(.navigationSettingTapped) }
                ),
                backgroundColor: .backgroundNormalAlternative
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileCard
                        .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        if store.userType == .tenant {
                            tenantActivitySection
                            tenantLivingGuideSection
                        } else if store.userType == .landlord {
                            landlordServiceSection
                        }

                        customerSupportSection
                    }
                    .padding(16)
                    .background(.neutral5)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(.backgroundNormalAlternative)
        }
        .background(.backgroundNormalAlternative)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func handleMenuItemTapped(_ item: MoreMenuItem) {
        switch item.action {
        case let .livingGuide(theme):
            store.send(.livingGuideItemTapped(theme))
        case .promoteRoom:
            store.send(.promoteRoomTapped)
        case nil:
            break
        }
    }

    @ViewBuilder private var profileCard: some View {
        if store.userType == .landlord {
            profileCardContent
        } else {
            Button {
                store.send(.editProfileTapped)
            } label: {
                profileCardContent
            }
            .buttonStyle(.plain)
        }
    }

    private var profileCardContent: some View {
        ZStack {
            Image(profileBackgroundName)
                .resizable()
                .scaledToFill()
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 8) {
                Image(profileIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 0) {
                    Text(profileNameText)
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(profileNameColor)

                    Text(profileNicknameText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(profileNicknameColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if store.userType != .landlord {
                    Image("pencil_write_24")
                        .renderingMode(.template)
                        .foregroundStyle(.staticWhite)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 76)
    }

    private var profileBackgroundName: String {
        store.userType == .landlord ? "landlordProfileBackground" : "tenantProfileBackground"
    }

    private var profileIconName: String {
        store.userType == .landlord ? "landlordProfileIcon" : "tenantProfileIcon"
    }

    private var profileNameText: String {
        guard let profile = store.userProfile else {
            return store.userType == .landlord ? "집주인 이름" : "닉네임"
        }

        switch profile.userType {
        case .tenant:
            let fullName = [profile.firstName, profile.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
            return fullName.isEmpty ? profile.nickname : fullName

        case .landlord:
            return profile.name ?? profile.nickname

        case .unknown:
            return profile.nickname
        }
    }

    private var profileNicknameText: String {
        store.userProfile?.nickname ?? ""
    }

    private var profileNameColor: Color {
        store.userType == .landlord ? .neutral85 : .neutral5
    }

    private var profileNicknameColor: Color {
        store.userType == .landlord ? .neutral75 : .primary5
    }

    private var tenantActivitySection: some View {
        MoreMenuSection(
            title: "내 활동",
            items: [
                .init(title: "찜한 매물", iconName: "heart_24"),
                .init(title: "최근 본 매물", iconName: "thunder_24")
            ],
            horizontalPadding: 16
        )
    }

    private var tenantLivingGuideSection: some View {
        MoreMenuSection(
            title: "한국 생활 팁",
            items: [
                .init(
                    title: "조심해야할 사기 유형",
                    iconName: "contractChecklist",
                    rendersAsTemplate: false,
                    action: .livingGuide(.housingScams)
                ),
                .init(
                    title: "은행 계좌 개설 방법",
                    iconName: "bankAccountGuide",
                    rendersAsTemplate: false,
                    action: .livingGuide(.bankAccount)
                ),
                .init(
                    title: "대중교통 이용 안내",
                    iconName: "train",
                    rendersAsTemplate: false,
                    action: .livingGuide(.publicTransit)
                ),
                .init(
                    title: "건강 보험 등록",
                    iconName: "healthInsurance",
                    rendersAsTemplate: false,
                    action: .livingGuide(.healthInsurance)
                )
            ],
            horizontalPadding: 16,
            onItemTapped: handleMenuItemTapped
        )
    }

    private var landlordServiceSection: some View {
        MoreMenuSection(
            title: "사장님 서비스",
            items: [
                .init(
                    title: "무료로 방 등록하기",
                    subtitle: "고시원 · 쉐어하우스 · 코리빙 등",
                    iconName: "external_link_24",
                    action: .promoteRoom
                )
            ],
            horizontalPadding: 16,
            onItemTapped: handleMenuItemTapped
        )
    }

    private var customerSupportSection: some View {
        MoreMenuSection(
            title: "고객지원",
            items: [
                .init(title: "공지사항", iconName: "megaphone_24"),
                .init(title: "피드백 보내기", iconName: "mail_24"),
                .init(title: "협업 신청하기", iconName: "send_24")
            ],
            horizontalPadding: 16
        )
    }
}

private struct MoreMenuSection: View {
    let title: String
    let items: [MoreMenuItem]
    let horizontalPadding: CGFloat
    var onItemTapped: (MoreMenuItem) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.neutral30)
                .frame(height: 28, alignment: .center)

            VStack(spacing: 4) {
                ForEach(items) { item in
                    MoreMenuRow(item: item) {
                        onItemTapped(item)
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.staticWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MoreMenuRow: View {
    let item: MoreMenuItem
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                HStack(spacing: 4) {
                    if let iconName = item.iconName {
                        Image(iconName)
                            .renderingMode(item.rendersAsTemplate ? .template : .original)
                            .resizable()
                            .foregroundStyle(.coolNeutral40)
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .kohereTextStyle(.label2Medium)
                            .foregroundStyle(.neutral80)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .kohereTextStyle(.label3Medium)
                                .foregroundStyle(.neutral50)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image("chevron_right_16")
                    .renderingMode(.template)
                    .foregroundStyle(.coolNeutral40)
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
    var action: MoreMenuAction?

    var id: String { title }
}

private enum MoreMenuAction: Equatable {
    case livingGuide(LivingGuideTheme)
    case promoteRoom
}
