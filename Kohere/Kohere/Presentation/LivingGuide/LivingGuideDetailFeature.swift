//
//  LivingGuideDetailFeature.swift
//  Kohere
//
//  Created by soomin on 7/7/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LivingGuideDetailFeature {
    @Dependency(\.fetchLivingGuideTipsUseCase)
    var fetchLivingGuideTips

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
        case tipsResponse(Result<[LivingGuideTip], DataError>)
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isTipsLoading else { return .none }
                state.isTipsLoading = true
                state.tipsErrorMessage = nil

                return .run { [fetchLivingGuideTips, topicCode = state.guide.code] send in
                    do {
                        let tips = try await fetchLivingGuideTips.execute(topicCode)
                        await send(.tipsResponse(.success(tips)))
                    } catch {
                        await send(.tipsResponse(.failure(.from(error))))
                    }
                }

            case .backButtonTapped:
                return .none

            case let .tipsResponse(.success(tips)):
                state.isTipsLoading = false
                state.tipsErrorMessage = nil
                state.guide.tips = tips
                return .none

            case let .tipsResponse(.failure(error)):
                state.isTipsLoading = false
                state.tipsErrorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
