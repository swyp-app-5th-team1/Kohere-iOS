//
//  ListingApplicationPrivacyWebFeature.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ListingApplicationPrivacyWebFeature {
    @ObservableState
    struct State: Equatable {
        let title: String
        let url: URL
        var isLoading: Bool

        init(
            section: ListingApplicationPrivacySection,
            isLoading: Bool = true
        ) {
            title = section.title
            url = section.url
            self.isLoading = isLoading
        }
    }

    enum Action: Equatable {
        case backButtonTapped
        case loadingStarted
        case loadingFinished
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case .loadingStarted:
                state.isLoading = true
                return .none

            case .loadingFinished:
                state.isLoading = false
                return .none
            }
        }
    }
}
