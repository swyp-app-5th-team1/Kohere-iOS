//
//  ChatReportFeature.swift
//  Kohere
//
//  Created by soomin on 8/20/26.
//

import ComposableArchitecture

@Reducer
struct ChatReportFeature {
    @Dependency(\.reportChatRoomUseCase)
    var reportChatRoomUseCase

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
        var isSubmitting = false
    }
    
    // MARK: - Action

    @CasePathable
    enum Delegate: Equatable {
        case reportFinished(succeeded: Bool)
    }

    enum Action {
        case closeButtonTapped
        case reasonTapped(Reason)
        case reportButtonTapped
        case reportResponse(Result<ChatReport, Error>)
        case delegate(Delegate)
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
                guard let reason = state.selectedReason, !state.isSubmitting else { return .none }
                state.isSubmitting = true
                let roomID = state.roomID
                let report = reportChatRoomUseCase
                return .run { send in
                    do {
                        let response = try await report.execute(roomID, reason.domainReason)
                        await send(.reportResponse(.success(response)))
                    } catch {
                        await send(.reportResponse(.failure(error)))
                    }
                }

            case .reportResponse(.success):
                state.isSubmitting = false
                return .send(.delegate(.reportFinished(succeeded: true)))

            case .reportResponse(.failure):
                state.isSubmitting = false
                return .send(.delegate(.reportFinished(succeeded: false)))

            case .delegate:
                return .none
            }
        }
    }
}

private extension ChatReportFeature.Reason {
    var domainReason: ChatReportReason {
        switch self {
        case .abuse: .abuseHarassmentDiscrimination
        case .illegalInformation: .illegalContent
        case .sexualContent: .sexualInappropriateContent
        case .personalInformation: .personalInformation
        case .spam: .spam
        case .other: .other
        }
    }
}
