//
//  ListingDetailFeature.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import ComposableArchitecture
import Foundation

enum ListingDetailDelegate: Equatable {
    case applicationRequested(
        listingID: String,
        listingTitle: String,
        roomOfferID: String,
        roomTypeName: String,
        roomPricingText: String
    )
    case mapPreviewRequested(MapCoordinate)
}

@Reducer
struct ListingDetailFeature {
    @Dependency(\.fetchListingDetailUseCase)
    var fetchListingDetailUseCase
    @Dependency(\.listingClient)
    var listingClient

    @ObservableState
    struct State: Equatable {
        let listingID: String
        var detail: ListingDetailModel
        var userType: UserType?
        var isDetailLoading = false
        var isDetailLoaded = false
        var isApplicationDisabled = false
        var isFavoriteUpdating = false
        var isApplicationSheetPresented = false
        var selectedRoomOfferID: String?
        var isRoomTypeSelectorPresented = false
        var roomTypeValidationMessage: String?
        var errorMessage: String?

        init(
            listingID: String,
            userType: UserType? = nil,
            isApplicationDisabled: Bool = false
        ) {
            self.listingID = listingID
            self.detail = ListingDetailModel.mock(id: listingID)
            self.userType = userType
            self.isApplicationDisabled = isApplicationDisabled
        }
    }

    enum Action: Equatable {
        case onAppear
        case detailResponse(Result<ListingDetail, DataError>)
        case backButtonTapped
        case likeButtonTapped
        case favoriteStatusResponse(Result<ListingFavoriteStatus, DataError>)
        case shareButtonTapped
        case contactButtonTapped
        case applicationSheetDismissed
        case roomTypeSelectorTapped
        case roomOfferSelected(String)
        case applyButtonTapped
        case mapPreviewTapped
        case roomTypeValidationMessageDismissed
        case delegate(ListingDetailDelegate)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isDetailLoading,
                      !state.isDetailLoaded
                else { return .none }

                state.isDetailLoading = true
                state.errorMessage = nil

                return .run { [fetchListingDetailUseCase, listingID = state.listingID] send in
                    do {
                        let detail = try await fetchListingDetailUseCase.execute(listingID)
                        await send(.detailResponse(.success(detail)))
                    } catch {
                        await send(.detailResponse(.failure(.from(error))))
                    }
                }

            case let .detailResponse(.success(detail)):
                state.detail = ListingDetailModel(listingDetail: detail)
                state.isDetailLoading = false
                state.isDetailLoaded = true
                state.errorMessage = nil

                if let selectedRoomOfferID = state.selectedRoomOfferID,
                   !state.detail.roomOffers.contains(where: { $0.id == selectedRoomOfferID }) {
                    state.selectedRoomOfferID = nil
                }
                return .none

            case let .detailResponse(.failure(error)):
                state.isDetailLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .likeButtonTapped:
                guard state.canUseFavoriteFeatures,
                      !state.isFavoriteUpdating
                else { return .none }

                state.isFavoriteUpdating = true
                state.errorMessage = nil

                return .run { [listingClient, listingID = state.listingID, isLiked = state.detail.overview.isLiked] send in
                    do {
                        let status: ListingFavoriteStatus
                        if isLiked {
                            status = try await listingClient.removeFavorite(listingID)
                        } else {
                            status = try await listingClient.addFavorite(listingID)
                        }
                        await send(.favoriteStatusResponse(.success(status)))
                    } catch {
                        await send(.favoriteStatusResponse(.failure(.from(error))))
                    }
                }

            case let .favoriteStatusResponse(.success(status)):
                state.detail.overview.isLiked = status.isFavorited
                state.detail.overview.favoriteCount = status.favoriteCount
                state.isFavoriteUpdating = false
                state.errorMessage = nil
                return .none

            case let .favoriteStatusResponse(.failure(error)):
                state.isFavoriteUpdating = false
                state.errorMessage = error.localizedDescription
                return .none

            case .roomTypeSelectorTapped:
                guard state.canUseApplicationFeatures,
                      state.isApplicationSheetPresented
                else { return .none }

                state.isRoomTypeSelectorPresented.toggle()
                state.roomTypeValidationMessage = nil
                return .none

            case let .roomOfferSelected(roomOfferID):
                guard state.canUseApplicationFeatures,
                      state.isApplicationSheetPresented
                else { return .none }

                state.selectedRoomOfferID = roomOfferID
                state.isRoomTypeSelectorPresented = false
                state.roomTypeValidationMessage = nil
                return .none

            case .applyButtonTapped:
                guard state.canUseApplicationFeatures else { return .none }

                guard state.isApplicationSheetPresented else {
                    state.isApplicationSheetPresented = true
                    state.roomTypeValidationMessage = nil
                    return .none
                }

                guard let selectedRoomOffer = state.selectedRoomOffer else {
                    state.roomTypeValidationMessage = "방 유형을 선택해주세요"
                    return .run { send in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await send(.roomTypeValidationMessageDismissed)
                    }
                    .cancellable(id: "ListingDetail.roomTypeValidationMessage", cancelInFlight: true)
                }

                return .send(
                    .delegate(
                        .applicationRequested(
                            listingID: state.listingID,
                            listingTitle: state.detail.overview.title,
                            roomOfferID: selectedRoomOffer.id,
                            roomTypeName: selectedRoomOffer.name,
                            roomPricingText: selectedRoomOffer.pricingText
                        )
                    )
                )

            case .mapPreviewTapped:
                guard let coordinate = state.detail.locationInfo.coordinate else { return .none }
                return .send(.delegate(.mapPreviewRequested(coordinate)))

            case .applicationSheetDismissed:
                state.isApplicationSheetPresented = false
                state.isRoomTypeSelectorPresented = false
                state.roomTypeValidationMessage = nil
                return .none

            case .roomTypeValidationMessageDismissed:
                state.roomTypeValidationMessage = nil
                return .none

            case .backButtonTapped, .shareButtonTapped, .contactButtonTapped, .delegate:
                return .none
            }
        }
    }
}

extension ListingDetailFeature.State {
    var showsTenantActionBar: Bool {
        userType == .tenant
    }

    var canUseApplicationFeatures: Bool {
        showsTenantActionBar && !isApplicationDisabled
    }

    var canUseFavoriteFeatures: Bool {
        showsTenantActionBar
    }

    var selectedRoomOffer: ListingRoomOfferModel? {
        guard let selectedRoomOfferID else { return nil }
        return detail.roomOffers.first { $0.id == selectedRoomOfferID }
    }
}
