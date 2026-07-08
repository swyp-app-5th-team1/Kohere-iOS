//
//  LivingGuideDetailFeature.swift
//  Kohere
//
//  Created by mandoo on 7/7/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LivingGuideDetailFeature {
    @Dependency(\.lifeTipClient)
    var lifeTipClient

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var guide: LivingGuide
        var isTipsLoading: Bool = false
        var tipsErrorMessage: String?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case backButtonTapped
        case lifeTipsResponse(Result<[LivingGuideTip], DataError>)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isTipsLoading else { return .none }
                state.isTipsLoading = true
                state.tipsErrorMessage = nil

                return .run { [lifeTipClient, topicCode = state.guide.code] send in
                    do {
                        let tips = try await lifeTipClient.fetchTips(topicCode)
                        await send(.lifeTipsResponse(.success(tips)))
                    } catch {
                        await send(.lifeTipsResponse(.failure(.from(error))))
                    }
                }

            case .backButtonTapped:
                return .none

            case let .lifeTipsResponse(.success(tips)):
                state.isTipsLoading = false
                state.tipsErrorMessage = nil
                state.guide.tips = tips
                return .none

            case let .lifeTipsResponse(.failure(error)):
                state.isTipsLoading = false
                state.tipsErrorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
