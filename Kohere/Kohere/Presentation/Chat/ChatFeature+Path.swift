//
//  ChatFeature+Path.swift
//  Kohere
//
//  Created by Codex on 9/26/26.
//

import ComposableArchitecture

extension ChatFeature {
    func handlePathAction(_ action: StackActionOf<Path>, state: inout State) -> Effect<Action> {
        switch action {
        case .element(id: _, action: .chatDetail(.delegate(.dismissRequested))):
            _ = state.path.popLast()
            return fetchChatRooms(page: 0, state: &state)

        case .element(id: _, action: .chatBot(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(id: _, action: .chatBot(.mapRequested(request))):
            return .send(.delegate(.mapRequested(request)))

        case let .element(id: _, action: .chatDetail(.delegate(.listingDetailRequested(listingID, isApplicationDisabled)))):
            state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID,
                                                                        userType: state.participantRole.userType,
                                                                        appLanguage: state.appLanguage,
                                                                        isApplicationDisabled: isApplicationDisabled)))
            return .none

        case let .element(id: _, action: .chatDetail(.delegate(.swipeActionRequested(swipeAction, roomID)))):
            return .send(.swipeActionTapped(swipeAction, roomID: roomID))

        case let .element(id: _, action: .chatDetail(.delegate(.errorMessageRequested(message)))):
            return .send(.delegate(.popupRequested(Self.errorPopup(message: message, language: state.appLanguage))))

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
            state.path.append(.listingApplication(ListingApplicationFeature.State(listingID: listingID,
                                                                                  listingTitle: listingTitle,
                                                                                  roomOfferID: roomOfferID,
                                                                                  roomTypeName: roomTypeName,
                                                                                  roomPricingText: roomPricingText,
                                                                                  appLanguage: state.appLanguage)))
            return .none

        case let .element(id: _, action: .listingDetail(.delegate(.inquiryChatRoomRequested(roomID, listingID)))):
            let room = ChatRoomModel(roomID: roomID, myRole: .tenant, listingID: listingID,
                                     listingName: "", location: "")
            state.path.removeAll()
            state.path.append(.chatDetail(ChatDetailFeature.State(chatRoom: room,
                                                                  hasSubmittedApplication: false,
                                                                  showsInquiryCard: true)))
            return .none

        case .element(id: _, action: .listingApplication(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(id: _, action: .listingApplication(.bookingResponse(.success(booking)))):
            state.pendingBookingListingIDs.insert(booking.listingID)
            state.hasLoadedInitialPage = false
            return .none

        case let .element(
            id: _,
            action: .listingApplication(.delegate(.privacyDocumentRequested(section)))
        ):
            state.path.append(.listingApplicationPrivacyWeb(
                ListingApplicationPrivacyWebFeature.State(section: section, appLanguage: state.appLanguage)
            ))
            return .none

        case .element(id: _, action: .listingApplicationPrivacyWeb(.backButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(
            id: _,
            action: .listingApplication(.delegate(.listingDetailRequested(listingID)))
        ):
            state.path.removeAll()
            state.path.append(.listingDetail(ListingDetailFeature.State(listingID: listingID,
                                                                        userType: state.participantRole.userType,
                                                                        appLanguage: state.appLanguage,
                                                                        isApplicationDisabled: true)))
            return .none

        case let .element(
            id: _,
            action: .listingApplication(.delegate(.chatRoomRequested(listingID)))
        ):
            return .send(.chatRoomForListingRequested(listingID))

        case .element(id: _, action: .report(.closeButtonTapped)):
            _ = state.path.popLast()
            return .none

        case let .element(id: _, action: .report(.delegate(.reportFinished(succeeded)))):
            if succeeded { _ = state.path.popLast() }
            return .send(.delegate(.popupRequested(Self.resultPopup(for: .report, succeeded: succeeded,
                                                                    language: state.appLanguage))))

        default:
            return .none
        }
    }
}
