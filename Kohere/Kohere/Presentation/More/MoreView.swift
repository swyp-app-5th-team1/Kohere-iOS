//
//  MoreView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MoreView: View {
    @Environment(\.locale)
    private var locale

    let store: StoreOf<MoreFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .smallLogo,
                center: .text(localized("more.title")),
                right: .moreTab(
                    showsLanguage: store.userType != .landlord,
                    languagePopover: NavigationPopover(
                        isPresented: store.isLanguagePopoverPresented,
                        onPresentationChanged: {
                            store.send(.languagePopoverPresentationChanged($0))
                        },
                        content: AnyView(languagePopover)
                    ),
                    onLanguage: { store.send(.navigationLanguageTapped) },
                    onSetting: { store.send(.navigationSettingTapped) }
                ),
                backgroundColor: .backgroundNormalAlternative
            )

            if store.userType != nil {
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
            } else {
                Spacer()
            }
        }
        .background(.backgroundNormalAlternative)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var languagePopover: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(localized("language.current"))
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral50)

                Spacer(minLength: 8)

                Text(store.selectedLanguage.title)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.primary50)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)

            Divider()
                .foregroundStyle(.lineAlternative)

            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    store.send(.languageSelected(language))
                } label: {
                    HStack(spacing: 8) {
                        Text(language.title)
                            .kohereTextStyle(.label1Medium)
                            .foregroundStyle(.neutral80)

                        Spacer(minLength: 8)

                        if store.selectedLanguage == language {
                            Image(.check24)
                                .renderingMode(.template)
                                .foregroundStyle(.primary50)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 220)
        .padding(.vertical, 8)
        .background(.common0)
    }

    private func handleMenuItemTapped(_ item: MoreMenuItem) {
        switch item.action {
        case .savedListings:
            store.send(.savedListingsTapped)
        case .recentlyViewedListings:
            store.send(.recentlyViewedListingsTapped)
        case .announcements:
            store.send(.announcementsTapped)
        case let .livingGuide(theme):
            store.send(.livingGuideItemTapped(theme))
        case .promoteRoom:
            store.send(.promoteRoomTapped)
        case .feedback:
            store.send(.feedbackTapped)
        case .collaboration:
            store.send(.collaborationTapped)
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
            return store.userType == .landlord
                ? localized("more.profile.landlordNamePlaceholder")
                : localized("more.profile.nicknamePlaceholder")
        }

        switch profile.userType {
        case .tenant:
            let name = profile.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? profile.nickname : name

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
            title: localized("more.activity.title"),
            items: [
                .init(
                    title: localized("more.activity.savedListings"),
                    iconName: "heart_24",
                    action: .savedListings
                ),
                .init(
                    title: localized("more.activity.recentlyViewed"),
                    iconName: "thunder_24",
                    action: .recentlyViewedListings
                )
            ],
            horizontalPadding: 16,
            onItemTapped: handleMenuItemTapped
        )
    }

    private var tenantLivingGuideSection: some View {
        MoreMenuSection(
            title: localized("home.livingGuide.title"),
            items: [
                .init(
                    title: localized("home.livingGuide.fraud.title"),
                    iconName: "contractChecklist",
                    rendersAsTemplate: false,
                    action: .livingGuide(.housingScams)
                ),
                .init(
                    title: localized("home.livingGuide.bankAccount.title"),
                    iconName: "bankAccountGuide",
                    rendersAsTemplate: false,
                    action: .livingGuide(.bankAccount)
                ),
                .init(
                    title: localized("home.livingGuide.transportation.title"),
                    iconName: "train",
                    rendersAsTemplate: false,
                    action: .livingGuide(.publicTransit)
                ),
                .init(
                    title: localized("home.livingGuide.healthInsurance.title"),
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
                    title: localized("more.landlordService.promoteRoom"),
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
            title: localized("more.support.title"),
            items: [
                .init(
                    title: localized("more.support.announcements"),
                    iconName: "megaphone_24",
                    action: .announcements
                ),
                .init(
                    title: localized("more.support.feedback"),
                    iconName: "mail_24",
                    action: .feedback
                ),
                .init(
                    title: localized("more.support.partner"),
                    iconName: "send_24",
                    action: .collaboration
                )
            ],
            horizontalPadding: 16,
            onItemTapped: handleMenuItemTapped
        )
    }

    private func localized(_ key: String) -> String {
        AppLanguage(locale: locale).localized(key)
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
    case savedListings
    case recentlyViewedListings
    case announcements
    case livingGuide(LivingGuideTheme)
    case promoteRoom
    case feedback
    case collaboration
}
