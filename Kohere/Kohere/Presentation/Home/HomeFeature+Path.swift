//
//  HomeFeature+Path.swift
//  Kohere
//
//  Created by soomin on 7/9/26.
//

import ComposableArchitecture

extension HomeFeature {
    func handlePathAction(_ action: StackActionOf<Path>, state: inout State) -> Effect<Action> {
        switch action {
        case .element(id: _, action: .savedListings(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .recentlyViewedList(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .listingDetail(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(
            id: _,
            action: .listingDetail(
                .delegate(
                    .applicationRequested(listingID, listingTitle, roomOfferID, roomTypeName, roomPricingText)
                )
            )
        ):
            state.path.append(
                .listingApplication(
                    ListingApplicationFeature.State(listingID: listingID, listingTitle: listingTitle, roomOfferID: roomOfferID,
                                                    roomTypeName: roomTypeName, roomPricingText: roomPricingText, appLanguage: state.appLanguage)
                )
            )
            return .none

        case let .element(
            id: _,
            action: .listingDetail(.delegate(.mapPreviewRequested(coordinate)))
        ):
            state.path.removeAll()
            return .send(.delegate(.listingMapPreviewRequested(coordinate)))

        case .element(id: _, action: .listingDetail(.likeButtonTapped)) where state.userType == nil:
            return .send(.delegate(.authenticationRequired))

        case let .element(id: _, action: .listingDetail(.popupRequested(popup))):
            return .send(.delegate(.popupRequested(popup)))

        case let .element(id: id, action: .listingDetail(.favoriteStatusResponse(.success(status)))):
            guard let listingID = state.path[id: id, case: \.listingDetail]?.listingID else { return .none }
            return .send(.delegate(.favoriteStatusChanged(listingID: listingID, status: status)))

        case .element(id: _, action: .listingApplication(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(
            id: _,
            action: .listingApplication(.delegate(.privacyDocumentRequested(section)))
        ):
            state.path.append(
                .listingApplicationPrivacyWeb(
                    ListingApplicationPrivacyWebFeature.State(section: section, appLanguage: state.appLanguage)
                )
            )
            return .none

        case let .element(
            id: _,
            action: .listingApplication(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.removeAll()
            state.path.append(
                .listingDetail(
                    ListingDetailFeature.State(listingID: listingID, userType: state.userType, appLanguage: state.appLanguage, isApplicationDisabled: true)
                )
            )
            return .none

        case let .element(id: _, action: .listingApplication(.delegate(.chatRoomRequested(listingID)))):
            state.path.removeAll()
            return .send(.delegate(.chatRoomRequested(listingID: listingID)))

        case let .element(
            id: _,
            action: .savedListings(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.append(listingDetailState(listingID, userType: state.userType, appLanguage: state.appLanguage))
            return .none

        case let .element(
            id: _,
            action: .recentlyViewedList(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.append(listingDetailState(listingID, userType: state.userType, appLanguage: state.appLanguage))
            return .none

        case let .element(
            id: _,
            action: .savedListings(.favoriteStatusResponse(listingID, .success(status)))
        ), let .element(
            id: _,
            action: .recentlyViewedList(.favoriteStatusResponse(listingID, .success(status)))
        ):
            return .send(.delegate(.favoriteStatusChanged(listingID: listingID, status: status)))

        case .element(id: _, action: .notifications(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .chatBot(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .livingGuideDetail(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .search(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(id: _, action: .chatBot(.mapRequested(request))):
            return .send(.delegate(.mapRequested(request)))

        case .element(id: _, action: .search(.bannerTapped)):
            state.path.append(.chatBot(ChatBotFeature.State()))
            return .none

        case let .element(id: _, action: .search(.placeResultTapped(placeResult))):
            state.path.removeAll()
            return .send(.delegate(.mapPlaceSearchRequested(placeResult)))

        case let .element(id: _, action: .search(.popupRequested(popup))):
            return .send(.delegate(.popupRequested(popup)))

        default:
            return .none
        }
    }

    private func listingDetailState(_ listingID: String, userType: UserType?, appLanguage: AppLanguage) -> Path.State {
        .listingDetail(
            ListingDetailFeature.State(listingID: listingID, userType: userType, appLanguage: appLanguage)
        )
    }
}
