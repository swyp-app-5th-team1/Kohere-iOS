//
//  AccountView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import SwiftUI

struct AccountView: View {
    @Environment(\.locale)
    private var locale

    let store: StoreOf<AccountFeature>

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            content
        }
        .background(.coolNeutral5)
        .interactivePopGestureEnabled()
    }
}

private extension AccountView {
    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text(localized(.settingsAccountTitle)),
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
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                ForEach(accountFields) { field in
                    AccountField(title: field.title, value: field.value)
                }
            }

            deleteAccountButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    var deleteAccountButton: some View {
        Button {
            store.send(.deleteAccountButtonTapped)
        } label: {
            Text(.accountDeleteAccountTitle)
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.coolNeutral10)
                .underline()
                .frame(height: 32, alignment: .center)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    var accountFields: [AccountFieldModel] {
        switch resolvedUserType {
        case .tenant:
            return [
                .init(title: .accountLinkedEmailTitle, value: store.userProfile?.email ?? ""),
                .init(title: .accountDateOfBirthTitle, value: formattedBirthDate),
                .init(title: .accountGenderTitle, value: formattedGender)
            ]

        case .landlord:
            return [
                .init(title: .accountLinkedEmailTitle, value: store.userProfile?.email ?? ""),
                .init(title: .accountDateOfBirthTitle, value: formattedBirthDate)
            ]

        case .unknown:
            return [
                .init(title: .accountLinkedEmailTitle, value: store.userProfile?.email ?? "")
            ]
        }
    }

    var resolvedUserType: UserType {
        store.userProfile?.userType ?? store.userType
    }

    var formattedBirthDate: String {
        guard let birthDate = store.userProfile?.birthDate else { return "" }
        return birthDate.replacingOccurrences(of: "-", with: ".")
    }

    var formattedGender: String {
        switch store.userProfile?.gender {
        case Gender.male.rawValue:
            return localized(.accountGenderMale)
        case Gender.female.rawValue:
            return localized(.accountGenderFemale)
        case let gender?:
            return gender
        case nil:
            return ""
        }
    }

    func localized(_ resource: LocalizedStringResource) -> String {
        AppLanguage(locale: locale).localized(resource)
    }
}

private struct AccountField: View {
    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(.coolNeutral40)
                .padding(.horizontal, 4)

            Text(value)
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.coolNeutral40)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .padding(.horizontal, 16)
                .background(.coolNeutral7)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct AccountFieldModel: Identifiable, Equatable {
    let title: LocalizedStringResource
    let value: String

    var id: String {
        title.key
    }
}
