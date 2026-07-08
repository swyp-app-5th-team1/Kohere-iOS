//
//  ProfileEditFeature.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ProfileEditFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var nickname: String
        var email: String

        var firstName: String
        var lastName: String
        var selectedNationality: DropdownMenuOption?
        var selectedGender: DropdownMenuOption?
        var selectedVisa: DropdownMenuOption?
        var selectedOccupation: DropdownMenuOption?
        private let userProfile: UserProfile?

        var isSaveButtonEnabled: Bool {
            hasRequiredFields
            && hasChanges
        }

        private var hasRequiredFields: Bool {
            !Self.normalizedText(firstName).isEmpty
            && !Self.normalizedText(lastName).isEmpty
            && selectedVisa != nil
            && selectedOccupation != nil
        }

        init(userProfile: UserProfile? = nil) {
            self.userProfile = userProfile
            nickname = userProfile?.nickname ?? ""
            email = userProfile?.email ?? ""
            firstName = userProfile?.firstName ?? ""
            lastName = userProfile?.lastName ?? ""
            selectedNationality = userProfile?.countryName.map(DropdownMenuOption.init(option:))
            selectedGender = Self.genderOption(from: userProfile?.gender)
            selectedVisa = Self.visaOption(from: userProfile?.visaType)
            selectedOccupation = Self.occupationOption(from: userProfile?.occupation)
        }

        private var hasChanges: Bool {
            Self.normalizedText(firstName) != Self.normalizedText(userProfile?.firstName ?? "")
            || Self.normalizedText(lastName) != Self.normalizedText(userProfile?.lastName ?? "")
            || selectedNationality != userProfile?.countryName.map(DropdownMenuOption.init(option:))
            || selectedGender != Self.genderOption(from: userProfile?.gender)
            || selectedVisa != Self.visaOption(from: userProfile?.visaType)
            || selectedOccupation != Self.occupationOption(from: userProfile?.occupation)
        }

        private static func normalizedText(_ text: String) -> String {
            text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static func genderOption(from rawValue: String?) -> DropdownMenuOption? {
            guard let rawValue,
                  let gender = Gender(rawValue: rawValue)
            else { return nil }

            return DropdownMenuOption(gender)
        }

        private static func visaOption(from rawValue: String?) -> DropdownMenuOption? {
            guard let rawValue,
                  let visaType = VisaType(rawValue: rawValue)
            else { return nil }

            return DropdownMenuOption(visaType)
        }

        private static func occupationOption(from rawValue: String?) -> DropdownMenuOption? {
            guard let rawValue,
                  let occupation = Occupation(rawValue: rawValue)
            else { return nil }

            return DropdownMenuOption(occupation)
        }
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case backButtonTapped
        case saveButtonTapped
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding:
                return .none

            case .backButtonTapped:
                return .none

            case .saveButtonTapped:
                return .none
            }
        }
    }
}
