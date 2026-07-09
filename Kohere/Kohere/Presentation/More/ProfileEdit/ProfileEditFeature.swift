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
    @Dependency(\.updateProfileUseCase)
    var updateProfileUseCase

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
        var isSaving = false
        private let userProfile: UserProfile?

        var isSaveButtonEnabled: Bool {
            !isSaving
            && profileUpdate != nil
            && hasChanges
        }

        var profileUpdate: UserProfileUpdate? {
            guard hasRequiredFields,
                  let occupation = selectedOccupation?.occupation,
                  let visaType = selectedVisa?.visaType
            else { return nil }

            return UserProfileUpdate(
                firstName: Self.normalizedText(firstName),
                lastName: Self.normalizedText(lastName),
                gender: selectedGender?.gender,
                birthDate: userProfile?.birthDate,
                country: selectedNationality?.nationalityCountryCode ?? userProfile?.country,
                occupation: occupation,
                visaType: visaType,
                name: userProfile?.name,
                phoneNumber: userProfile?.phoneNumber,
                marketingAgreed: userProfile?.marketingAgreed
            )
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
            selectedNationality = Self.nationalityOption(from: userProfile?.country)
            selectedGender = Self.genderOption(from: userProfile?.gender)
            selectedVisa = Self.visaOption(from: userProfile?.visaType)
            selectedOccupation = Self.occupationOption(from: userProfile?.occupation)
        }

        private var hasChanges: Bool {
            Self.normalizedText(firstName) != Self.normalizedText(userProfile?.firstName ?? "")
            || Self.normalizedText(lastName) != Self.normalizedText(userProfile?.lastName ?? "")
            || selectedNationality != Self.nationalityOption(from: userProfile?.country)
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

        private static func nationalityOption(from countryCode: String?) -> DropdownMenuOption? {
            DropdownMenuOption.nationalityOption(countryCode: countryCode)
        }
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case backButtonTapped
        case saveButtonTapped
        case updateProfileResponse(Result<UserProfile, DataError>)
        case delegate(Delegate)
    }

    enum Delegate: Equatable {
        case profileUpdated(UserProfile)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .backButtonTapped:
                return .none

            case .saveButtonTapped:
                guard state.isSaveButtonEnabled,
                      let update = state.profileUpdate
                else { return .none }

                state.isSaving = true
                let updateProfileUseCase = updateProfileUseCase

                return .run { send in
                    do {
                        let userProfile = try await updateProfileUseCase.execute(update)
                        await send(.updateProfileResponse(.success(userProfile)))
                    } catch {
                        await send(.updateProfileResponse(.failure(DataError.from(error))))
                    }
                }

            case let .updateProfileResponse(.success(userProfile)):
                state.isSaving = false
                return .send(.delegate(.profileUpdated(userProfile)))

            case let .updateProfileResponse(.failure(error)):
                state.isSaving = false
                Self.debugLogUpdateFailure(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension ProfileEditFeature {
    static func debugLogUpdateFailure(_ error: DataError) {
#if DEBUG
        print("[ProfileEdit] update profile failed: \(error.debugDescription)")
#endif
    }
}
