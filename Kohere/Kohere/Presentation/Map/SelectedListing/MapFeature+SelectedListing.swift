import ComposableArchitecture
import Foundation

extension MapFeature {
    func selectMarker(_ listingID: String, state: inout State) -> Effect<Action> {
        guard state.selectedMarkerID != listingID else { return .none }
        state.clearSelectedListing()
        state.selectedMarkerID = listingID
        state.sheetMode = .selectedListing

        // 이미 목록에 있는 매물은 카드 데이터를 그대로 사용한다.
        guard state.selectedListingItem == nil else {
            return .cancel(id: MapEffectID.selectedListing)
        }

        // ID로 대상을 지정하고, 카드에는 현재 적용한 검색 조건을 그대로 반영한다.
        let input = state.appliedFilter.listingSearchInput(listingIDs: [listingID], size: 1)
        let requestID = uuid()
        state.selectedListingRequestID = requestID
        return .run { [listingClient] send in
            do {
                let page = try await listingClient.fetchListings(input)
                try Task.checkCancellation()
                // 필터에 맞지 않거나 비공개/삭제된 매물은 응답에서 빠질 수 있다.
                guard let listing = page.content.first(where: { $0.listingID == listingID }) else {
                    throw DataError.emptyResponse
                }
                await send(.selectedListingResponse(requestID: requestID, .success(listing)))
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                await send(.selectedListingResponse(requestID: requestID, .failure(.from(error))))
            }
        }
        .cancellable(id: MapEffectID.selectedListing, cancelInFlight: true)
    }

    func handleSelectedListingResponse(
        requestID: UUID,
        result: Result<Listing, DataError>,
        state: inout State
    ) -> Effect<Action> {
        // A → B → A 선택도 구분한다. 선택 해제·검색 변경 후의 응답 역시 무시한다.
        guard state.selectedListingRequestID == requestID else { return .none }
        state.selectedListingRequestID = nil

        if case let .success(listing) = result,
           listing.listingID == state.selectedMarkerID {
            state.selectedListing = listing
            return .none
        }

        state.clearSelectedListing()
        return .send(.popupRequested(.notice(AppPopup.Notice(
            message: state.appLanguage.localized(.listingDetailErrorLoadFailed),
            confirmTitle: state.appLanguage.localized(.commonConfirm)
        ))))
    }
}
