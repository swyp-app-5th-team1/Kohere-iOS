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
    @Dependency(\.fetchKRWToUSDExchangeRateUseCase)
    var fetchKRWToUSDExchangeRateUseCase
    @Dependency(\.convertMonthlyRentCurrencyUseCase)
    var convertMonthlyRentCurrencyUseCase

    @ObservableState
    struct State: Equatable {
        let listingID: String
        var detail: ListingDetailModel?
        var listingDetail: ListingDetail?
        var krwToUSDExchangeRate: KRWToUSDExchangeRate?
        var userType: UserType?
        var appLanguage: AppLanguage
        var isDetailLoading = false
        var isDetailLoaded = false
        var isExchangeRateLoading = false
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
            appLanguage: AppLanguage = .systemDefault,
            isApplicationDisabled: Bool = false
        ) {
            self.listingID = listingID
            self.userType = userType
            self.appLanguage = appLanguage
            self.isApplicationDisabled = isApplicationDisabled
        }
    }

    enum Action: Equatable {
        case onAppear
        case detailResponse(Result<ListingDetail, DataError>)
        case exchangeRateResponse(Result<KRWToUSDExchangeRate, CurrencyError>)
        case popupRequested(AppPopup)
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
                state.isExchangeRateLoading = state.krwToUSDExchangeRate == nil
                state.errorMessage = nil

                let detailEffect: Effect<Action> = .run { [fetchListingDetailUseCase, listingID = state.listingID] send in
                    do {
                        let detail = try await fetchListingDetailUseCase.execute(listingID)
                        await send(.detailResponse(.success(detail)))
                    } catch {
                        await send(.detailResponse(.failure(.from(error))))
                    }
                }

                guard state.isExchangeRateLoading else { return detailEffect }

                let exchangeRateEffect: Effect<Action> = .run { [fetchKRWToUSDExchangeRateUseCase] send in
                    do {
                        let exchangeRate = try await fetchKRWToUSDExchangeRateUseCase.execute()
                        await send(.exchangeRateResponse(.success(exchangeRate)))
                    } catch {
                        await send(.exchangeRateResponse(.failure(.exchangeRateUnavailable)))
                    }
                }

                return .merge(detailEffect, exchangeRateEffect)

            case let .detailResponse(.success(detail)):
                state.listingDetail = detail
                state.detail = makeDetailModel(
                    from: detail,
                    exchangeRate: state.krwToUSDExchangeRate,
                    language: state.appLanguage
                )
                state.isDetailLoading = false
                state.isDetailLoaded = true
                state.errorMessage = nil

                if let selectedRoomOfferID = state.selectedRoomOfferID,
                   !detail.roomOffers.contains(where: { $0.id == selectedRoomOfferID }) {
                    state.selectedRoomOfferID = nil
                }
                return .none

            case .detailResponse(.failure):
                state.isDetailLoading = false
                return .send(
                    .popupRequested(Self.detailLoadFailurePopup(language: state.appLanguage))
                )

            case let .exchangeRateResponse(.success(exchangeRate)):
                state.krwToUSDExchangeRate = exchangeRate
                state.isExchangeRateLoading = false

                guard let listingDetail = state.listingDetail else { return .none }

                let currentFavoriteStatus = state.detail.map {
                    (isLiked: $0.overview.isLiked, favoriteCount: $0.overview.favoriteCount)
                }
                state.detail = makeDetailModel(
                    from: listingDetail,
                    exchangeRate: exchangeRate,
                    language: state.appLanguage
                )
                state.detail?.overview.isLiked = currentFavoriteStatus?.isLiked
                    ?? listingDetail.isFavorited
                state.detail?.overview.favoriteCount = currentFavoriteStatus?.favoriteCount
                    ?? listingDetail.favoriteCount
                return .none

            case .exchangeRateResponse(.failure):
                state.isExchangeRateLoading = false
                return .none

            case .likeButtonTapped:
                guard state.canUseFavoriteFeatures,
                      !state.isFavoriteUpdating,
                      let detail = state.detail
                else { return .none }

                state.isFavoriteUpdating = true
                state.errorMessage = nil

                return .run { [listingClient, listingID = state.listingID, isLiked = detail.overview.isLiked] send in
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
                guard state.detail != nil else { return .none }
                state.detail?.overview.isLiked = status.isFavorited
                state.detail?.overview.favoriteCount = status.favoriteCount
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
                guard state.canUseApplicationFeatures,
                      let detail = state.detail
                else { return .none }

                guard state.isApplicationSheetPresented else {
                    state.isApplicationSheetPresented = true
                    state.roomTypeValidationMessage = nil
                    return .none
                }

                guard let selectedRoomOffer = state.selectedRoomOffer else {
                    state.roomTypeValidationMessage = String(
                        localized: "listingDetail.validation.roomTypeRequired"
                    )
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
                            listingTitle: detail.overview.title,
                            roomOfferID: selectedRoomOffer.id,
                            roomTypeName: selectedRoomOffer.name,
                            roomPricingText: selectedRoomOffer.pricingText
                        )
                    )
                )

            case .mapPreviewTapped:
                guard let coordinate = state.detail?.locationInfo.coordinate else { return .none }
                return .send(.delegate(.mapPreviewRequested(coordinate)))

            case .applicationSheetDismissed:
                state.isApplicationSheetPresented = false
                state.isRoomTypeSelectorPresented = false
                state.roomTypeValidationMessage = nil
                return .none

            case .roomTypeValidationMessageDismissed:
                state.roomTypeValidationMessage = nil
                return .none

            case .backButtonTapped, .shareButtonTapped, .contactButtonTapped, .popupRequested, .delegate:
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
        showsTenantActionBar && !isApplicationDisabled && detail != nil
    }

    var canUseFavoriteFeatures: Bool {
        showsTenantActionBar && detail != nil
    }

    var selectedRoomOffer: ListingRoomOfferModel? {
        guard let selectedRoomOfferID,
              let detail
        else { return nil }
        return detail.roomOffers.first { $0.id == selectedRoomOfferID }
    }
}

private extension ListingDetailFeature {
    func makeDetailModel(
        from listingDetail: ListingDetail,
        exchangeRate: KRWToUSDExchangeRate?,
        language: AppLanguage
    ) -> ListingDetailModel {
        ListingDetailModel(
            listingDetail: listingDetail,
            exchangeRate: exchangeRate,
            convertMonthlyRentCurrencyUseCase: convertMonthlyRentCurrencyUseCase,
            language: language
        )
    }

    static func detailLoadFailurePopup(language: AppLanguage) -> AppPopup {
        .notice(
            AppPopup.Notice(
                message: language.localized("listingDetail.error.loadFailed"),
                confirmTitle: language.localized("common.confirm"),
                confirmRoute: .dismissListingDetail
            )
        )
    }
}
