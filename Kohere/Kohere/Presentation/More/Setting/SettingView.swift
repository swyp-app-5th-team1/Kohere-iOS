//
//  SettingView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import SwiftUI

struct SettingView: View {
    @Environment(\.locale)
    private var locale

    let store: StoreOf<SettingFeature>

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            content
        }
        .background(.coolNeutral5)
    }
}

private extension SettingView {
    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text(localized("settings.title")),
            right: .none,
            backgroundColor: .coolNeutral5
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                SettingMenuSection(
                    items: [
                        .init(title: localized("settings.account.title"), action: .account)
                    ],
                    onItemTapped: { store.send(.settingItemTapped($0)) }
                )

                SettingMenuSection(
                    items: [
                        .init(title: localized("settings.customerTerms.title"), action: .termsOfService),
                        .init(title: localized("settings.privacyPolicy.title"), action: .privacyPolicy),
                        .init(title: localized("settings.marketingConsent.title"), action: .marketingAgreement)
                    ],
                    onItemTapped: { store.send(.settingItemTapped($0)) }
                )

                appVersionRow
            }

            logoutButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    var appVersionRow: some View {
        HStack {
            Text(localized("settings.appVersion.current"))

            Spacer()

            Text("v.\(store.appVersion)")
        }
        .kohereTextStyle(.label2Medium)
        .foregroundStyle(.coolNeutral10)
        .padding(.horizontal, 4)
        .frame(height: 20)
    }

    var logoutButton: some View {
        Button {
            store.send(.logoutButtonTapped)
        } label: {
            Text(localized("settings.logout.title"))
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.coolNeutral10)
                .underline()
                .frame(height: 32, alignment: .center)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    func localized(_ key: String) -> String {
        AppLanguage(locale: locale).localized(key)
    }
}

private struct SettingMenuSection: View {
    let items: [SettingMenuItem]
    let onItemTapped: (SettingFeature.SettingItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                SettingMenuRow(
                    title: item.title,
                    action: { onItemTapped(item.action) }
                )
            }
        }
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SettingMenuRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral80)

                Spacer()

                Image(.chevronRight16)
                    .renderingMode(.template)
                    .foregroundStyle(.coolNeutral20)
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingMenuItem: Identifiable, Equatable {
    let title: String
    let action: SettingFeature.SettingItem

    var id: SettingFeature.SettingItem {
        action
    }
}
