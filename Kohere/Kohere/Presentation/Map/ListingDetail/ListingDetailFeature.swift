//
//  ListingDetailFeature.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import ComposableArchitecture

@Reducer
struct ListingDetailFeature {
    @ObservableState
    struct State: Equatable {
        var detail: ListingDetailModel

        init(listingID: String) {
            self.detail = ListingDetailModel.mock(id: listingID)
        }
    }

    enum Action: Equatable {
        case backButtonTapped
        case likeButtonTapped
        case shareButtonTapped
        case contactButtonTapped
        case applyButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .likeButtonTapped:
                state.detail.overview.isLiked.toggle()
                return .none

            case .backButtonTapped, .shareButtonTapped, .contactButtonTapped, .applyButtonTapped:
                return .none
            }
        }
    }
}
