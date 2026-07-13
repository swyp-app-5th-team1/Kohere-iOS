//
//  HomeFeature+Path.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture

extension HomeFeature {
    func handlePathAction(
        _ action: StackActionOf<Path>,
        state: inout State
    ) -> Effect<Action> {
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
                    .applicationRequested(
                        listingID,
                        listingTitle,
                        roomOfferID,
                        roomTypeName,
                        roomPricingText
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

        case let .element(
            id: _,
            action: .listingDetail(.delegate(.mapPreviewRequested(coordinate)))
        ):
            state.path.removeAll()
            return .send(.listingMapPreviewRequested(coordinate))

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
                    ListingApplicationPrivacyWebFeature.State(section: section)
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
                    ListingDetailFeature.State(
                        listingID: listingID,
                        userType: state.userType,
                        isApplicationDisabled: true
                    )
                )
            )
            return .none

        case .element(id: _, action: .listingApplication(.delegate(.chatTabRequested))):
            state.path.removeAll()
            return .send(.chatTabRequested)

        case let .element(
            id: _,
            action: .savedListings(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.append(listingDetailState(listingID, userType: state.userType))
            return .none

        case let .element(
            id: _,
            action: .recentlyViewedList(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.append(listingDetailState(listingID, userType: state.userType))
            return .none

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

        case let .element(id: _, action: .chatBot(.mapTabRequested(diagnosisID))):
            return .send(.mapTabRequested(diagnosisID: diagnosisID))

        case .element(id: _, action: .search(.bannerTapped)):
            state.path.append(.chatBot(ChatBotFeature.State()))
            return .none

        case let .element(id: _, action: .search(.placeResultTapped(placeResult))):
            state.path.removeAll()
            return .send(.mapPlaceSearchRequested(placeResult))

        default:
            return .none
        }
    }

    private func listingDetailState(
        _ listingID: String,
        userType: UserType?
    ) -> Path.State {
        .listingDetail(
            ListingDetailFeature.State(
                listingID: listingID,
                userType: userType
            )
        )
    }
}
