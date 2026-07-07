//
//  AccountView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import SwiftUI

struct AccountView: View {
    let store: StoreOf<AccountFeature>

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            content
        }
        .background(.coolNeutral5)
    }
}

private extension AccountView {
    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text("계정"),
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
            Text("계정 삭제하기")
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
                .init(title: "연결된 이메일", value: store.userProfile?.email ?? ""),
                .init(title: "생년월일", value: formattedBirthDate),
                .init(title: "성별", value: formattedGender)
            ]

        case .landlord:
            return [
                .init(title: "연결된 이메일", value: store.userProfile?.email ?? ""),
                .init(title: "사업자 등록 번호", value: store.userProfile?.businessRegistrationNumber ?? ""),
                .init(title: "생년월일", value: formattedBirthDate)
            ]

        case .unknown:
            return [
                .init(title: "연결된 이메일", value: store.userProfile?.email ?? "")
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
            return "남성"
        case Gender.female.rawValue:
            return "여성"
        case let gender?:
            return gender
        case nil:
            return ""
        }
    }
}

private struct AccountField: View {
    let title: String
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
    let title: String
    let value: String

    var id: String {
        title
    }
}
