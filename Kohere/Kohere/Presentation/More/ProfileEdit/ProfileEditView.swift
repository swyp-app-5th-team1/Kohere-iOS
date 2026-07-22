//
//  ProfileEditView.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import ComposableArchitecture
import SwiftUI

struct ProfileEditView: View {

    // MARK: - Property

    @Bindable var store: StoreOf<ProfileEditFeature>
    @Environment(\.locale)
    private var locale
    @State private var activeField: ProfileEditField?
    @FocusState private var keyboardField: ProfileEditField?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            profileForm
        }
        .background(.backgroundNormalAlternative)
        .interactivePopGestureEnabled()
    }
}

// MARK: - Subviews

private extension ProfileEditView {
    func dismissKeyboard() {
        activeField = nil
        keyboardField = nil
    }

    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text(String(localized: "profileEdit.title", locale: locale)),
            right: .checkButton(
                isEnabled: store.isSaveButtonEnabled,
                action: { store.send(.saveButtonTapped) }
            ),
            backgroundColor: .backgroundNormalAlternative
        )
    }

    var profileForm: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    
                    nameFields
                    
                    nationalityAndGenderFields
                        .zIndex(2)
                    visaStatusField
                        .zIndex(1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background {
                Color.backgroundNormalAlternative
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
            }
            .onChange(of: activeField) { _, newValue in
                scrollToActiveField(newValue, proxy: proxy)
            }
        }
    }

    var profileHeader: some View {
        VStack(spacing: 3) {
            Image("tenantProfileIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 73, height: 73)

            Text(store.nickname)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.neutral70)
                .lineLimit(1)

            Text(store.email)
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.neutral30)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    var nameFields: some View {
        VStack(spacing: 16) {
            ProfileEditTextField(
                title: String(localized: "onboarding.profile.firstName", locale: locale),
                text: $store.firstName,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .firstName,
                isRequired: true,
                characterLimit: 100
            )
            .id(ProfileEditField.firstName)

            ProfileEditTextField(
                title: String(localized: "onboarding.profile.lastName", locale: locale),
                text: $store.lastName,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .lastName,
                isRequired: true
            )
            .id(ProfileEditField.lastName)
        }
    }

    var nationalityAndGenderFields: some View {
        HStack(spacing: 8) {
            ProfileEditDropdownField(
                title: "onboarding.profile.nationality",
                selectedOption: $store.selectedNationality,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .nationality,
                options: DropdownMenuOption.nationalities,
                listHeight: 176
            )
            .id(ProfileEditField.nationality)
            .zIndex(2)

            ProfileEditDropdownField(
                title: "onboarding.profile.gender",
                selectedOption: $store.selectedGender,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .gender,
                options: DropdownMenuOption.genders,
                listHeight: 92
            )
            .id(ProfileEditField.gender)
            .zIndex(1)
        }
    }

    var visaStatusField: some View {
        ProfileEditDropdownField(
            title: "onboarding.profile.visaStatus",
            selectedOption: $store.selectedVisa,
            activeField: $activeField,
            keyboardField: $keyboardField,
            equals: .visaStatus,
            options: DropdownMenuOption.visas,
            listHeight: 239,
            isRequired: true
        )
        .id(ProfileEditField.visaStatus)
    }

    func scrollToActiveField(_ field: ProfileEditField?, proxy: ScrollViewProxy) {
        guard let field else { return }

        withAnimation(.easeInOut) {
            proxy.scrollTo(field, anchor: .center)
        }
    }
}
