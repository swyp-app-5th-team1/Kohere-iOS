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

    @Reducer
    enum Path {
        case account(AccountFeature)
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
        case navigationSettingTapped
        case editProfileTapped
        case livingGuideItemTapped(LivingGuideTheme)
        case promoteRoomTapped
        case savedListingsTapped
        case recentlyViewedListingsTapped
        case userProfileUpdated(UserProfile)
        case popupRequested(AppPopup)
        case mapCoordinateRequested(MapCoordinate)
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
                return .send(.mapCoordinateRequested(coordinate))

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
                            isApplicationDisabled: true
                        )
                    )
                )
                return .none

            case .path(.element(id: _, action: .listingApplication(.delegate(.chatTabRequested)))):
                state.path.removeAll()
                return .send(.chatTabRequested)

            case let .path(.element(id: _, action: .savedListings(.delegate(.listingDetailRequested(listingID))))):
                state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID, userType: state.userType)))
                return .none

            case let .path(.element(id: _, action: .recentlyViewedList(.delegate(.listingDetailRequested(listingID))))):
                state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID, userType: state.userType)))
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
                return .none

            case .navigationSettingTapped:
                state.path.append(.setting(SettingFeature.State()))
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

            case .savedListingsTapped:
                guard state.canUseFavoriteFeatures else { return .none }
                state.path.append(.savedListings(SavedListingsFeature.State(userType: state.userType)))
                return .none

            case .recentlyViewedListingsTapped:
                state.path.append(.recentlyViewedList(RecentlyViewedFeature.State(userType: state.userType)))
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

            case .popupRequested, .mapCoordinateRequested, .chatTabRequested, .logoutConfirmed, .deleteAccountConfirmed:
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
