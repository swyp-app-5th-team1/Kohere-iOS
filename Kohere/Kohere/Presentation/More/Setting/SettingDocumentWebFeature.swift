//
//  SettingDocumentWebFeature.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import ComposableArchitecture
import Foundation

enum SettingDocument: Equatable {
    case termsOfService
    case privacyPolicy
    case marketingAgreement

    var url: URL {
        switch self {
        case .termsOfService:
            URL(string: "https://jewel-humor-b3e.notion.site/39777dadb98580ad9a47eda58626c047?source=copy_link")!
        case .privacyPolicy:
            URL(string: "https://jewel-humor-b3e.notion.site/39777dadb9858039b2aedef03251cdf4?source=copy_link")!
        case .marketingAgreement:
            URL(string: "https://jewel-humor-b3e.notion.site/39077dadb985802ba1a8ffb0472238e4?source=copy_link")!
        }
    }
}

@Reducer
struct SettingDocumentWebFeature {
    @ObservableState
    struct State: Equatable {
        let document: SettingDocument
        let url: URL
        var isLoading: Bool

        init(
            document: SettingDocument,
            isLoading: Bool = true
        ) {
            self.document = document
            self.url = document.url
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

extension SettingFeature.SettingItem {
    var document: SettingDocument? {
        switch self {
        case .account:
            nil
        case .termsOfService:
            .termsOfService
        case .privacyPolicy:
            .privacyPolicy
        case .marketingAgreement:
            .marketingAgreement
        }
    }
}
