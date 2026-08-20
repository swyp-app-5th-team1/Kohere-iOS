//
//  ChatReportFeature.swift
//  Kohere
//
//  Created by soomin on 8/20/26.
//

import ComposableArchitecture

@Reducer
struct ChatReportFeature {
    enum Reason: String, CaseIterable, Equatable, Identifiable {
        case abuse
        case illegalInformation
        case sexualContent
        case personalInformation
        case spam
        case other

        var id: Self { self }

        var localizationKey: String {
            switch self {
            case .abuse: "chat.report.reason.abuse"
            case .illegalInformation: "chat.report.reason.illegal-information"
            case .sexualContent: "chat.report.reason.sexual-content"
            case .personalInformation: "chat.report.reason.personal-information"
            case .spam: "chat.report.reason.spam"
            case .other: "chat.report.reason.other"
            }
        }
    }
    
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let roomID: Int
        let appLanguage: AppLanguage
        var selectedReason: Reason?
    }
    
    // MARK: - Action

    enum Action: Equatable {
        case closeButtonTapped
        case reasonTapped(Reason)
        case reportButtonTapped
    }
    
    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .none

            case let .reasonTapped(reason):
                state.selectedReason = reason
                return .none

            case .reportButtonTapped:
                guard state.selectedReason != nil else { return .none }
                // TODO: 신고 API 확정 후 연동
                return .none
            }
        }
    }
}
