//
//  SettingView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import SwiftUI

struct SettingView: View {
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
            center: .text("설정"),
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
                        .init(title: "계정", action: .account)
                    ],
                    onItemTapped: { store.send(.settingItemTapped($0)) }
                )

                SettingMenuSection(
                    items: [
                        .init(title: "고객 이용약관", action: .termsOfService),
                        .init(title: "개인정보처리방침", action: .privacyPolicy),
                        .init(title: "마케팅 정보동의", action: .marketingAgreement)
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
            Text("현재 앱 버전")

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
            Text("로그아웃")
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.coolNeutral10)
                .underline()
                .frame(height: 32, alignment: .center)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
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
