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
    @State private var activeField: ProfileEditField?
    @FocusState private var keyboardField: ProfileEditField?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            profileForm
        }
        .background(Color.backgroundNormalAlternative)
    }
}

// MARK: - Subviews

private extension ProfileEditView {
    var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton({ store.send(.backButtonTapped) }),
            center: .text("Edit Profile"),
            right: .none,
            backgroundColor: .backgroundNormalAlternative
        )
    }

    var profileForm: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    nameFields
                    dropdownFields
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .onChange(of: activeField) { _, newValue in
                scrollToActiveField(newValue, proxy: proxy)
            }
        }
    }

    var nameFields: some View {
        VStack(spacing: 16) {
            ProfileEditTextField(
                title: "First Name",
                text: $store.firstName,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .firstName,
                isRequired: true,
                characterLimit: 100
            )
            .id(ProfileEditField.firstName)

            ProfileEditTextField(
                title: "Last Name",
                text: $store.lastName,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .lastName,
                isRequired: true
            )
            .id(ProfileEditField.lastName)
        }
    }

    var dropdownFields: some View {
        HStack(spacing: 8) {
            ProfileEditDropdownField(
                title: "Nationality",
                selectedOption: $store.selectedNationality,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .nationality,
                options: DropdownMenuOption.nationalities,
                listHeight: 176
            )
            .id(ProfileEditField.nationality)

            ProfileEditDropdownField(
                title: "Gender",
                selectedOption: $store.selectedGender,
                activeField: $activeField,
                keyboardField: $keyboardField,
                equals: .gender,
                options: DropdownMenuOption.genders,
                listHeight: 92
            )
            .id(ProfileEditField.gender)
        }
    }

    func scrollToActiveField(_ field: ProfileEditField?, proxy: ScrollViewProxy) {
        guard let field else { return }

        withAnimation(.easeInOut) {
            proxy.scrollTo(field, anchor: .center)
        }
    }
}
