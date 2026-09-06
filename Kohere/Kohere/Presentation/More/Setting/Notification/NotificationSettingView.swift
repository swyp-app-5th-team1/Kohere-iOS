//
//  NotificationSettingView.swift
//  Kohere
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct NotificationSettingView: View {
    @Environment(\.locale)
    private var locale

    let store: StoreOf<NotificationSettingFeature>

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                chatNotificationSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
            }
        }
        .background(.coolNeutral5)
        .interactivePopGestureEnabled()
        .task {
            await store.send(.task).finish()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.send(.willEnterForeground)
        }
    }
}

private extension NotificationSettingView {
    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text(AppLanguage(locale: locale).localized(.settingsNotificationsTitle)),
            right: .none,
            backgroundColor: .coolNeutral5
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
    }

    var chatNotificationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.settingsNotificationChatTitle)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.coolNeutral40)
                .frame(minHeight: KohereTextStyle.label2Semibold.lineHeight)
                .padding(.horizontal, 4)

            if let messageTitle {
                if store.showsSkeleton {
                    NotificationSettingSkeleton(
                        title: messageTitle,
                        isAnimating: store.isLoading
                    )
                } else {
                    chatNotificationToggle(title: messageTitle)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func chatNotificationToggle(title: LocalizedStringResource) -> some View {
        Toggle(
            isOn: Binding(
                get: { store.isChatPushEnabled },
                set: { store.send(.chatPushEnabledChanged($0)) }
            )
        ) {
            Text(title)
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.coolNeutral70)
                .frame(minHeight: KohereTextStyle.label2Medium.lineHeight)
        }
        .toggleStyle(NotificationSettingToggleStyle())
        .disabled(!store.canInteractWithToggle)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var messageTitle: LocalizedStringResource? {
        switch store.userType {
        case .tenant:
            .settingsNotificationLandlordMessagesTitle
        case .landlord:
            .settingsNotificationTenantMessagesTitle
        case .unknown:
            nil
        }
    }
}

private struct NotificationSettingSkeleton: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isDimmed = false

    let title: LocalizedStringResource
    let isAnimating: Bool

    private var shouldAnimate: Bool { isAnimating && !reduceMotion }

    var body: some View {
        // 실제 카드와 같은 글꼴·여백으로 크기를 잡고, 카드 전체를 하나의 로딩 영역으로 표시한다.
        Text(title)
            .kohereTextStyle(.label2Medium)
            .frame(minHeight: KohereTextStyle.label2Medium.lineHeight)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.coolNeutral8)
            }
            .opacity(isDimmed ? 0.45 : 1)
            .animation(
                shouldAnimate ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : nil,
                value: isDimmed
            )
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(.commonLoading))
            .accessibilityHidden(!isAnimating)
            .onAppear {
                isDimmed = shouldAnimate
            }
            .onChange(of: shouldAnimate) { _, value in
                isDimmed = value
            }
    }
}

private struct NotificationSettingToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 0) {
                configuration.label

                Spacer(minLength: 0)

                Capsule()
                    .fill(configuration.isOn ? Color.basePrimary : Color.gray400)
                    .frame(width: 36, height: 20)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.staticWhite)
                            .frame(width: 16, height: 16)
                            .padding(2)
                    }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
            .toggleStyle(.switch)
        }
    }
}

#Preview("임차인 · 영어") {
    NotificationSettingView(
        store: Store(initialState: NotificationSettingFeature.State(
            userType: .tenant, serverChatPushEnabled: true,
            authorization: .authorized, loadState: .loaded
        )) {
            NotificationSettingFeature()
        }
    )
    .environment(\.locale, AppLanguage.english.locale)
}

#Preview("임대인 · 한국어") {
    NotificationSettingView(
        store: Store(initialState: NotificationSettingFeature.State(
            userType: .landlord, language: .korean, serverChatPushEnabled: false,
            authorization: .authorized, loadState: .loaded
        )) {
            NotificationSettingFeature()
        }
    )
    .environment(\.locale, AppLanguage.korean.locale)
}
