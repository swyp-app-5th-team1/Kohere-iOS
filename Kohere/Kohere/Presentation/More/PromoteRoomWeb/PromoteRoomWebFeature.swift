//
//  PromoteRoomWebFeature.swift
//  Kohere
//
//  Created by Codex on 7/2/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PromoteRoomWebFeature {
    @ObservableState
    struct State: Equatable {
        let url: URL

        init(
            url: URL = URL(string: "https://forms.gle/1aZdZgBLeHd4b1zr7")!
        ) {
            self.url = url
        }
    }

    enum Action: Equatable {
        case backButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .none
            }
        }
    }
}
