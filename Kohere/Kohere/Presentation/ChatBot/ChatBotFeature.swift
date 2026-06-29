//
//  ChatBotFeature.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatBotFeature {
    enum ChatItem: Equatable, Identifiable {
        case bot(id: UUID, text: String, isFirst: Bool)
        case user(id: UUID, text: String)
        
        var id: UUID {
            switch self {
            case .bot(let id, _, _): return id
            case .user(let id, _): return id
            }
        }
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var currentStep: Int = 1
        var history: [ChatItem] = []
        var selectedOptionCodes: Set<String> = []
        
        var currentDiagnosis: Diagnosis? {
            Diagnosis.mockDiagnosisList.first { $0.step == currentStep }
        }
        
        var isConfirmButtonEnabled: Bool {
            guard let maxCount = currentDiagnosis?.maxSelectCount else { return false }
            return !selectedOptionCodes.isEmpty && selectedOptionCodes.count <= maxCount
        }
        
        var isFindButtonEnabled: Bool {
            return currentStep >= 7
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case backButtonTapped
        case onAppear
        case optionTapped(DiagnosisOption)
        case confirmButtonTapped
        case findButtonTapped
        case resetButtonTapped
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none
                
            case .onAppear:
                guard state.history.isEmpty else { return .none }
                
                state.history.append(.bot(id: UUID(), text: "Welcome 👋", isFirst: true))
                if let firstQ = state.currentDiagnosis {
                    state.history.append(.bot(id: UUID(), text: firstQ.question, isFirst: false))
                }
                return .none
                
            case let .optionTapped(option):
                guard let diagnosis = state.currentDiagnosis else { return .none }
                
                if diagnosis.selectType == .single {
                    state.history.append(.user(id: UUID(), text: option.label))
                    
                    let nextStep = state.currentStep + 1
                    if Diagnosis.mockDiagnosisList.contains(where: { $0.step == nextStep }) {
                        state.currentStep = nextStep
                        if let nextQ = state.currentDiagnosis {
                            state.history.append(.bot(id: UUID(), text: nextQ.question, isFirst: true))
                        }
                    } else {
                        state.currentStep = nextStep
                    }
                    return .none
                }
                
                if diagnosis.selectType == .multi {
                    if state.selectedOptionCodes.contains(option.code) {
                        state.selectedOptionCodes.remove(option.code)
                    } else {
                        if state.selectedOptionCodes.count < diagnosis.maxSelectCount {
                            state.selectedOptionCodes.insert(option.code)
                        }
                    }
                }
                return .none
                
            case .confirmButtonTapped:
                guard let diagnosis = state.currentDiagnosis,
                      diagnosis.selectType == .multi,
                      state.isConfirmButtonEnabled else { return .none }
                
                let userText = diagnosis.options
                    .filter { state.selectedOptionCodes.contains($0.code) }
                    .map { $0.label }
                    .joined(separator: ", ")
                
                state.history.append(.user(id: UUID(), text: userText))
                state.selectedOptionCodes.removeAll()
                
                state.currentStep += 1
                if let nextQ = state.currentDiagnosis {
                    state.history.append(.bot(id: UUID(), text: nextQ.question, isFirst: true))
                }
                return .none
                
            case .findButtonTapped:
                // TODO: 지도 탭으로 연결
                return .none
                
            case .resetButtonTapped:
                state.currentStep = 1
                state.history.removeAll()
                state.selectedOptionCodes.removeAll()
                return .send(.onAppear)
            }
        }
    }
}
