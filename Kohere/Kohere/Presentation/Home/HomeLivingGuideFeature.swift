//
//  HomeLivingGuideFeature.swift
//  Kohere
//
//  Created by soomin on 7/31/26.
//

import ComposableArchitecture
import Foundation

private extension HomeLivingGuideFeature {
    enum EffectID {
        static let lifeTips = "HomeFeature.lifeTips"
    }
}

@Reducer
struct HomeLivingGuideFeature {
    @Dependency(\.lifeTipClient)
    var lifeTipClient
    
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var guides: [LivingGuide]
        var isLoading = false
        var isLoaded: Bool
        var errorMessage: String?

        init(guides: [LivingGuide] = []) {
            self.guides = guides
            self.isLoaded = !guides.isEmpty
        }
    }
    
    // MARK: - Action

    enum Action {
        case onAppear
        case cancelEffects
        case itemTapped(id: Int)
        case topicsResponse(Result<[LivingGuide], DataError>)
    }
    
    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading, !state.isLoaded else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { [lifeTipClient] send in
                    do {
                        let topics = try await lifeTipClient.fetchTopics()
                        await send(.topicsResponse(.success(topics)))
                    } catch {
                        await send(.topicsResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: EffectID.lifeTips, cancelInFlight: true)

            case .cancelEffects:
                return .cancel(id: EffectID.lifeTips)

            case .itemTapped:
                return .none

            case let .topicsResponse(.success(guides)):
                state.isLoading = false
                state.isLoaded = true
                state.errorMessage = nil
                state.guides = guides
                return .none

            case let .topicsResponse(.failure(error)):
                state.isLoading = false
                state.isLoaded = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

