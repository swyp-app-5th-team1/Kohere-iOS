//
//  MoreFeature+Path.swift
//  Kohere
//

import ComposableArchitecture

extension MoreFeature {
    func reducePath(_ action: StackActionOf<Path>, state: inout State) -> Effect<Action> {
        switch action {
        case .element(id: _, action: .account(.backButtonTapped)),
             .element(id: _, action: .announcements(.backButtonTapped)),
             .element(id: _, action: .profileEdit(.backButtonTapped)),
             .element(id: _, action: .livingGuideDetail(.backButtonTapped)),
             .element(id: _, action: .promoteRoomWeb(.backButtonTapped)),
             .element(id: _, action: .savedListings(.backButtonTapped)),
             .element(id: _, action: .recentlyViewedList(.backButtonTapped)),
             .element(id: _, action: .listingDetail(.backButtonTapped)),
             .element(id: _, action: .listingApplication(.backButtonTapped)),
             .element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped)),
             .element(id: _, action: .setting(.backButtonTapped)),
             .element(id: _, action: .settingDocumentWeb(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(id: _, action: .account(.popupRequested(popup))),
             let .element(id: _, action: .setting(.popupRequested(popup))):
            return .send(.popupRequested(popup))

        case let .element(id: _, action: .profileEdit(.delegate(.profileUpdated(userProfile)))):
            _ = state.path.popLast()
            return .send(.userProfileUpdated(userProfile))

        case let .element(id: _, action: .listingDetail(.delegate(.applicationRequested(listingID, listingTitle, roomOfferID, roomTypeName, roomPricingText)))):
            state.path.append(.listingApplication(ListingApplicationFeature.State(
                listingID: listingID, listingTitle: listingTitle, roomOfferID: roomOfferID,
                roomTypeName: roomTypeName, roomPricingText: roomPricingText,
                appLanguage: state.selectedLanguage
            )))
            return .none

        case let .element(id: _, action: .listingDetail(.delegate(.mapPreviewRequested(coordinate)))):
            state.path.removeAll()
            return .send(.listingMapPreviewRequested(coordinate))

        case let .element(id: _, action: .listingApplication(.delegate(.privacyDocumentRequested(section)))):
            state.path.append(.listingApplicationPrivacyWeb(ListingApplicationPrivacyWebFeature.State(
                section: section, appLanguage: state.selectedLanguage
            )))
            return .none

        case let .element(id: _, action: .listingApplication(.delegate(.listingDetailRequested(listingID)))):
            state.path.removeAll()
            state.path.append(.listingDetail(ListingDetailFeature.State(
                listingID: listingID, userType: state.userType, appLanguage: state.selectedLanguage,
                isApplicationDisabled: true
            )))
            return .none

        case let .element(id: _, action: .listingApplication(.delegate(.chatRoomRequested(listingID)))):
            state.path.removeAll()
            return .send(.chatRoomRequested(listingID: listingID))

        case let .element(id: _, action: .savedListings(.delegate(.listingDetailRequested(listingID)))),
             let .element(id: _, action: .recentlyViewedList(.delegate(.listingDetailRequested(listingID)))):
            state.path.append(.listingDetail(ListingDetailFeature.State(
                listingID: listingID, userType: state.userType, appLanguage: state.selectedLanguage
            )))
            return .none

        case .element(id: _, action: .setting(.settingItemTapped(.account))):
            state.path.append(.account(AccountFeature.State(
                userType: state.userType ?? .unknown, userProfile: state.userProfile,
                language: state.selectedLanguage
            )))
            return .none

        case let .element(id: _, action: .setting(.settingItemTapped(item))):
            guard let document = item.document else { return .none }
            state.path.append(.settingDocumentWeb(SettingDocumentWebFeature.State(document: document)))
            return .none

        default:
            return .none
        }
    }
}
