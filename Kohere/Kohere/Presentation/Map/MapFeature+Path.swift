//
//  MapFeature+Path.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture

extension MapFeature {
    func handlePathAction(
        _ action: StackActionOf<Path>,
        state: inout State
    ) -> Effect<Action> {
        switch action {
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
            state.selectedMarkerID = listingID
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

        case .element(id: _, action: .listingApplication(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .chatBot(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .search(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case .element(id: _, action: .search(.bannerTapped)):
            state.path.append(.chatBot(ChatBotFeature.State()))
            return .none

        case let .element(id: _, action: .search(.placeResultTapped(placeResult))):
            _ = state.path.popLast()
            return .send(.placeSearchResultSelected(placeResult))

        default:
            return .none
        }
    }
}
