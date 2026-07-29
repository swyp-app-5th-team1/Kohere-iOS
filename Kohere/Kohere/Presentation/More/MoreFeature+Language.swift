//
//  MoreFeature+Language.swift
//  Kohere
//

import ComposableArchitecture

extension MoreFeature {
    func reduceLanguage(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .navigationLanguageTapped:
            guard state.userType != .landlord, !state.isLanguageUpdateLoading else { return .none }
            state.isLanguagePopoverPresented.toggle()
            return .none

        case let .languagePopoverPresentationChanged(isPresented):
            state.isLanguagePopoverPresented = isPresented
            return .none

        case let .languageSelected(language):
            state.isLanguagePopoverPresented = false
            guard state.userType != .landlord, language != state.selectedLanguage else { return .none }
            return .send(.popupRequested(.action(AppPopup.Action(
                message: Self.localized("language.change.resetNotice", language: state.selectedLanguage),
                primaryTitle: Self.localized("language.change.confirm", language: state.selectedLanguage),
                secondaryTitle: Self.localized("language.change.cancel", language: state.selectedLanguage),
                route: .confirmLanguageChange(language)
            ))))

        case let .languageChangeConfirmed(language):
            guard state.userType != .landlord,
                  language != state.selectedLanguage,
                  !state.isLanguageUpdateLoading
            else { return .none }
            state.isLanguageUpdateLoading = true
            let updateProfileUseCase = updateProfileUseCase
            return .run { send in
                do {
                    let profile = try await updateProfileUseCase.execute(UserProfileUpdate(lang: language.rawValue))
                    await send(.languageUpdateResponse(language, .success(profile)))
                } catch {
                    await send(.languageUpdateResponse(language, .failure(DataError.from(error))))
                }
            }

        case let .languageUpdateResponse(language, .success(profile)):
            state.isLanguageUpdateLoading = false
            state.selectedLanguage = language
            state.userProfile = profile
            return .none

        case .languageUpdateResponse(_, .failure):
            state.isLanguageUpdateLoading = false
            return .send(.popupRequested(.notice(AppPopup.Notice(
                message: Self.localized("language.change.failure", language: state.selectedLanguage),
                confirmTitle: Self.localized("common.confirm", language: state.selectedLanguage)
            ))))

        default:
            return .none
        }
    }
}
