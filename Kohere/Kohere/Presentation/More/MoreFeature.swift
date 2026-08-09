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
        var selectedLanguage: AppLanguage = .english
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
            case let .path(pathAction):
                return reducePath(pathAction, state: &state)

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

            case .navigationLanguageTapped,
                 .languagePopoverPresentationChanged,
                 .languageSelected,
                 .languageChangeConfirmed,
                 .languageUpdateResponse:
                return reduceLanguage(action, state: &state)

            case .navigationSettingTapped:
                state.path.append(.setting(SettingFeature.State(language: state.selectedLanguage)))
                return .none

            case .announcementsTapped:
                state.path.append(.announcements(AnnouncementsFeature.State()))
                return .none

            case .editProfileTapped:
                guard state.userType == .tenant else { return .none }
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
                guard state.canUseFavoriteFeatures else { return .none }
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

extension MoreFeature {
    private static let supportEmail = "kohere26@gmail.com"

    private static func feedbackMailURL(language: AppLanguage) -> URL? {
        mailURL(
            body: language.localized(.moreSupportFeedbackMailBody)
        )
    }

    private static func collaborationMailURL(language: AppLanguage) -> URL? {
        mailURL(
            body: language.localized(.moreSupportCollaborationMailBody)
        )
    }

    private static func mailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
