//
//  MoreFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MoreFeature {
    @Dependency(\.lifeTipClient)
    var lifeTipClient

    @Dependency(\.openURL)
    var openURL

    @Dependency(\.updateProfileUseCase)
    var updateProfileUseCase

    @Reducer
    enum Path {
        case account(AccountFeature)
        case announcements(AnnouncementsFeature)
        case livingGuideDetail(LivingGuideDetailFeature)
        case profileEdit(ProfileEditFeature)
        case promoteRoomWeb(PromoteRoomWebFeature)
        case savedListings(SavedListingsFeature)
        case recentlyViewedList(RecentlyViewedFeature)
        case listingDetail(ListingDetailFeature)
        case listingApplication(ListingApplicationFeature)
        case listingApplicationPrivacyWeb(ListingApplicationPrivacyWebFeature)
        case setting(SettingFeature)
        case settingDocumentWeb(SettingDocumentWebFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var userType: UserType?
        var userProfile: UserProfile?
        var isLanguagePopoverPresented = false
        var selectedLanguage: AppLanguage = .systemDefault
        var isLanguageUpdateLoading = false
        var livingGuides: [LivingGuide] = []
        var isLivingGuidesLoading: Bool = false
        var isLivingGuidesLoaded: Bool = false
        var livingGuidesErrorMessage: String?
    }

    enum Action {
        case path(StackActionOf<Path>)
        case onAppear
        case lifeTipTopicsResponse(Result<[LivingGuide], DataError>)
        case navigationLanguageTapped
        case languagePopoverPresentationChanged(Bool)
        case languageSelected(AppLanguage)
        case languageChangeConfirmed(AppLanguage)
        case languageUpdateResponse(AppLanguage, Result<UserProfile, DataError>)
        case navigationSettingTapped
        case announcementsTapped
        case editProfileTapped
        case livingGuideItemTapped(LivingGuideTheme)
        case promoteRoomTapped
        case feedbackTapped
        case collaborationTapped
        case savedListingsTapped
        case recentlyViewedListingsTapped
        case userProfileUpdated(UserProfile)
        case popupRequested(AppPopup)
        case listingMapPreviewRequested(MapCoordinate)
        case chatTabRequested
        case logoutConfirmed
        case deleteAccountConfirmed
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .path(.element(id: _, action: .account(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .announcements(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .account(.popupRequested(popup)))):
                return .send(.popupRequested(popup))

            case .path(.element(id: _, action: .profileEdit(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .livingGuideDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .profileEdit(.delegate(.profileUpdated(userProfile))))):
                _ = state.path.popLast()
                return .send(.userProfileUpdated(userProfile))

            case .path(.element(id: _, action: .promoteRoomWeb(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .savedListings(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .recentlyViewedList(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .listingDetail(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(
                .element(
                    id: _,
                    action: .listingDetail(
                        .delegate(
                            .applicationRequested(
                                listingID,
                                listingTitle,
                                roomOfferID,
                                roomTypeName,
                                roomPricingText
                            )
                        )
                    )
                )
            ):
                state.path.append(
                    .listingApplication(
                        ListingApplicationFeature.State(
                            listingID: listingID,
                            listingTitle: listingTitle,
                            roomOfferID: roomOfferID,
                            roomTypeName: roomTypeName,
                            roomPricingText: roomPricingText
                        )
                    )
                )
                return .none

            case let .path(.element(id: _, action: .listingDetail(.delegate(.mapPreviewRequested(coordinate))))):
                state.path.removeAll()
                return .send(.listingMapPreviewRequested(coordinate))

            case .path(.element(id: _, action: .listingApplication(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .listingApplication(.delegate(.privacyDocumentRequested(section))))):
                state.path.append(
                    .listingApplicationPrivacyWeb(
                        ListingApplicationPrivacyWebFeature.State(section: section)
                    )
                )
                return .none

            case let .path(.element(id: _, action: .listingApplication(.delegate(.listingDetailRequested(listingID))))):
                state.path.removeAll()
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: listingID,
                            userType: state.userType,
                            appLanguage: state.selectedLanguage,
                            isApplicationDisabled: true
                        )
                    )
                )
                return .none

            case .path(.element(id: _, action: .listingApplication(.delegate(.chatTabRequested)))):
                state.path.removeAll()
                return .send(.chatTabRequested)

            case let .path(.element(id: _, action: .savedListings(.delegate(.listingDetailRequested(listingID))))):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: listingID,
                            userType: state.userType,
                            appLanguage: state.selectedLanguage
                        )
                    )
                )
                return .none

            case let .path(.element(id: _, action: .recentlyViewedList(.delegate(.listingDetailRequested(listingID))))):
                state.path.append(
                    .listingDetail(
                        ListingDetailFeature.State(
                            listingID: listingID,
                            userType: state.userType,
                            appLanguage: state.selectedLanguage
                        )
                    )
                )
                return .none

            case .path(.element(id: _, action: .setting(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case .path(.element(id: _, action: .settingDocumentWeb(.backButtonTapped))):
                _ = state.path.popLast()
                return .none

            case let .path(.element(id: _, action: .setting(.popupRequested(popup)))):
                return .send(.popupRequested(popup))

            case .path(.element(id: _, action: .setting(.settingItemTapped(.account)))):
                state.path.append(
                    .account(
                        AccountFeature.State(
                            userType: state.userType ?? .unknown,
                            userProfile: state.userProfile
                        )
                    )
                )
                return .none

            case let .path(.element(id: _, action: .setting(.settingItemTapped(item)))):
                guard let document = item.document else { return .none }
                state.path.append(
                    .settingDocumentWeb(SettingDocumentWebFeature.State(document: document))
                )
                return .none

            case .onAppear:
                guard state.userType == .tenant,
                      !state.isLivingGuidesLoading,
                      !state.isLivingGuidesLoaded
                else { return .none }

                state.isLivingGuidesLoading = true
                state.livingGuidesErrorMessage = nil

                return .run { [lifeTipClient] send in
                    do {
                        let topics = try await lifeTipClient.fetchTopics()
                        await send(.lifeTipTopicsResponse(.success(topics)))
                    } catch {
                        await send(.lifeTipTopicsResponse(.failure(.from(error))))
                    }
                }

            case let .lifeTipTopicsResponse(.success(guides)):
                state.isLivingGuidesLoading = false
                state.isLivingGuidesLoaded = true
                state.livingGuidesErrorMessage = nil
                state.livingGuides = guides
                return .none

            case let .lifeTipTopicsResponse(.failure(error)):
                state.isLivingGuidesLoading = false
                state.isLivingGuidesLoaded = false
                state.livingGuidesErrorMessage = error.localizedDescription
                return .none

            case .navigationLanguageTapped:
                guard !state.isLanguageUpdateLoading else { return .none }
                state.isLanguagePopoverPresented.toggle()
                return .none

            case let .languagePopoverPresentationChanged(isPresented):
                state.isLanguagePopoverPresented = isPresented
                return .none

            case let .languageSelected(language):
                state.isLanguagePopoverPresented = false

                guard language != state.selectedLanguage else { return .none }

                return .send(
                    .popupRequested(
                        .action(
                            AppPopup.Action(
                                message: Self.localized(
                                    "language.change.resetNotice",
                                    language: state.selectedLanguage
                                ),
                                primaryTitle: Self.localized(
                                    "language.change.confirm",
                                    language: state.selectedLanguage
                                ),
                                secondaryTitle: Self.localized(
                                    "language.change.cancel",
                                    language: state.selectedLanguage
                                ),
                                route: .confirmLanguageChange(language)
                            )
                        )
                    )
                )

            case let .languageChangeConfirmed(language):
                guard language != state.selectedLanguage,
                      !state.isLanguageUpdateLoading
                else { return .none }

                state.isLanguageUpdateLoading = true
                let updateProfileUseCase = updateProfileUseCase

                return .run { send in
                    do {
                        let profile = try await updateProfileUseCase.execute(
                            UserProfileUpdate(lang: language.rawValue)
                        )
                        await send(.languageUpdateResponse(language, .success(profile)))
                    } catch {
                        await send(
                            .languageUpdateResponse(
                                language,
                                .failure(DataError.from(error))
                            )
                        )
                    }
                }

            case let .languageUpdateResponse(language, .success(profile)):
                state.isLanguageUpdateLoading = false
                state.selectedLanguage = language
                state.userProfile = profile
                return .none

            case .languageUpdateResponse(_, .failure):
                state.isLanguageUpdateLoading = false
                return .send(
                    .popupRequested(
                        .notice(
                            AppPopup.Notice(
                                message: Self.localized(
                                    "language.change.failure",
                                    language: state.selectedLanguage
                                ),
                                confirmTitle: Self.localized(
                                    "common.confirm",
                                    language: state.selectedLanguage
                                )
                            )
                        )
                    )
                )

            case .navigationSettingTapped:
                state.path.append(.setting(SettingFeature.State()))
                return .none

            case .announcementsTapped:
                state.path.append(.announcements(AnnouncementsFeature.State()))
                return .none

            case .editProfileTapped:
                state.path.append(.profileEdit(ProfileEditFeature.State(userProfile: state.userProfile)))
                return .none

            case let .livingGuideItemTapped(theme):
                guard state.userType == .tenant,
                      let guide = state.livingGuides.first(where: { $0.theme == theme }) else {
                    return .none
                }
                state.path.append(.livingGuideDetail(LivingGuideDetailFeature.State(guide: guide)))
                return .none

            case .promoteRoomTapped:
                state.path.append(.promoteRoomWeb(PromoteRoomWebFeature.State()))
                return .none

            case .feedbackTapped:
                guard let mailURL = Self.feedbackMailURL(language: state.selectedLanguage) else {
                    return .none
                }
                return .run { [openURL] _ in
                    await openURL(mailURL)
                }

            case .collaborationTapped:
                guard let mailURL = Self.collaborationMailURL(language: state.selectedLanguage) else {
                    return .none
                }
                return .run { [openURL] _ in
                    await openURL(mailURL)
                }

            case .savedListingsTapped:
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(
                    .savedListings(
                        SavedListingsFeature.State(
                            userType: state.userType,
                            appLanguage: state.selectedLanguage
                        )
                    )
                )
                return .none

            case .recentlyViewedListingsTapped:
                state.path.append(
                    .recentlyViewedList(
                        RecentlyViewedFeature.State(
                            userType: state.userType,
                            appLanguage: state.selectedLanguage
                        )
                    )
                )
                return .none

            case let .userProfileUpdated(userProfile):
                state.userType = userProfile.userType
                state.userProfile = userProfile

                for id in state.path.ids {
                    state.path[id: id, case: \.account]?.userType = userProfile.userType
                    state.path[id: id, case: \.account]?.userProfile = userProfile
                }

                guard userProfile.userType == .tenant else { return .none }
                return .send(.onAppear)

            case .popupRequested,
                 .listingMapPreviewRequested,
                 .chatTabRequested,
                 .logoutConfirmed,
                 .deleteAccountConfirmed:
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MoreFeature.Path.State: Equatable {}

extension MoreFeature.State {
    var canUseFavoriteFeatures: Bool {
        userType == .tenant
    }
}

private extension MoreFeature {
    static let supportEmail = "kohere26@gmail.com"

    static func feedbackMailURL(language: AppLanguage) -> URL? {
        mailURL(
            body: language.localized("more.support.feedbackMailBody")
        )
    }

    static func collaborationMailURL(language: AppLanguage) -> URL? {
        mailURL(
            body: language.localized("more.support.collaborationMailBody")
        )
    }

    static func mailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    static func localized(_ key: String, language: AppLanguage) -> String {
        language.localized(key)
    }
}
