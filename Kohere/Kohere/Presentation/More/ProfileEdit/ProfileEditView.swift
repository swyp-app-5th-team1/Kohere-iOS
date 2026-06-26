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
                        .zIndex(3)
                    visaStatusField
                        .zIndex(2)
                    occupationField
                        .zIndex(1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .onChange(of: activeField) { _, newValue in
                scrollToActiveField(newValue, proxy: proxy)
            }
        }
    }

    var profileHeader: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(Color.primary50)
                .frame(width: 73, height: 73)
                .overlay(
                    Image(.person24)
                        .renderingMode(.template)
                        .foregroundStyle(Color.staticWhite)
                )
                .overlay(
                    Circle()
                        .stroke(Color.primary50, lineWidth: 1.5)
                )

            Text(store.nickname)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(Color.neutral70)
                .lineLimit(1)

            Text(store.email)
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(Color.neutral30)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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

    var nationalityAndGenderFields: some View {
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
            .zIndex(2)

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
            .zIndex(1)
        }
    }

    var visaStatusField: some View {
        ProfileEditDropdownField(
            title: "Visa Status",
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

    var occupationField: some View {
        ProfileEditDropdownField(
            title: "Occupation",
            selectedOption: $store.selectedOccupation,
            activeField: $activeField,
            keyboardField: $keyboardField,
            equals: .occupation,
            options: DropdownMenuOption.occupations,
            listHeight: 239,
            isRequired: true
        )
        .id(ProfileEditField.occupation)
    }

    func scrollToActiveField(_ field: ProfileEditField?, proxy: ScrollViewProxy) {
        guard let field else { return }

        withAnimation(.easeInOut) {
            proxy.scrollTo(field, anchor: .center)
        }
    }
}
