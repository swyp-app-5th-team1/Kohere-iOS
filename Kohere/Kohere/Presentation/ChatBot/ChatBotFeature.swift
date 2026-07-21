import ComposableArchitecture
import Foundation

@Reducer
struct ChatBotFeature {
    @Dependency(\.startDiagnosisFlowUseCase)
    var startDiagnosisFlowUseCase
    @Dependency(\.advanceDiagnosisFlowUseCase)
    var advanceDiagnosisFlowUseCase

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
        var currentQuestion: Diagnosis?
        var selectedOptionCodes: Set<String> = []
        var budgetRange = Self.defaultBudgetRange
        var completedDiagnosisID: String?
        var isQuestionLoading = false
        var isAnswerSaving = false
        
        var currentDiagnosis: Diagnosis? {
            currentQuestion
        }
        
        var isConfirmButtonEnabled: Bool {
            guard let maxCount = currentDiagnosis?.maxSelectCount else { return false }
            return !selectedOptionCodes.isEmpty && selectedOptionCodes.count <= maxCount
        }
        
        var isFindButtonEnabled: Bool {
            completedDiagnosisID != nil
        }

        var budgetAnswerText: String {
            "\(budgetRange.minimum)~\(budgetRange.maximum)만원"
        }

        static let defaultBudgetRange = RangeSliderValue(
            minimum: MapFilterPriceRange.monthlyRent.lowerBound,
            maximum: 50,
            bounds: MapFilterPriceRange.monthlyRent
        )

        static func budgetPriceText(_ value: Int) -> String {
            if value >= 100, value % 100 == 0 {
                return "₩\(value / 100)M"
            }

            return "₩\(value * 10)K"
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case backButtonTapped
        case onAppear
        case flowResponse(Result<DiagnosisFlowResult, Error>)
        case optionTapped(DiagnosisOption)
        case confirmButtonTapped
        case budgetMinimumChanged(Int)
        case budgetMaximumChanged(Int)
        case budgetConfirmButtonTapped
        case findButtonTapped
        case resetButtonTapped
        case mapRequested(MapEntryRequest)
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
                state.isQuestionLoading = true

                return .run { send in
                    await send(.flowResponse(Result {
                        try await startDiagnosisFlowUseCase.execute()
                    }))
                }

            case let .flowResponse(.success(.nextQuestion(question))):
                state.isQuestionLoading = false
                state.isAnswerSaving = false
                state.selectedOptionCodes.removeAll()
                state.currentStep = question.step
                state.currentQuestion = question
                state.history.append(.bot(
                    id: UUID(),
                    text: question.question,
                    isFirst: state.isNextBotMessageFirst
                ))
                return .none

            case .flowResponse(.success(.restart)):
                state.resetConversation()
                return .send(.onAppear)

            case .flowResponse(.success(.terminated)):
                state.isQuestionLoading = false
                state.isAnswerSaving = false
                return .send(.backButtonTapped)

            case let .flowResponse(.success(.completed(diagnosisID))):
                state.isQuestionLoading = false
                state.isAnswerSaving = false
                state.selectedOptionCodes.removeAll()
                state.currentQuestion = nil
                state.currentStep = 7
                state.completedDiagnosisID = diagnosisID
                return .none

            case let .flowResponse(.failure(error)):
                state.isQuestionLoading = false
                state.isAnswerSaving = false

                if case let DataError.serverError(code, _) = error,
                   code == "DIAGNOSIS_SESSION_NOT_FOUND" {
                    state.resetConversation()
                    return .send(.onAppear)
                }

                return .none
                
            case let .optionTapped(option):
                guard let diagnosis = state.currentDiagnosis, !state.isAnswerSaving else { return .none }
                
                if diagnosis.selectType == .single {
                    state.history.append(.user(id: UUID(), text: option.title))

                    state.isAnswerSaving = true
                    let answer = DiagnosisAnswer.single(field: diagnosis.field, code: option.id)

                    return .run { send in
                        await send(.flowResponse(Result {
                            try await advanceDiagnosisFlowUseCase.execute(answer)
                        }))
                    }
                }
                
                if diagnosis.selectType == .multi {
                    if state.selectedOptionCodes.contains(option.id) {
                        state.selectedOptionCodes.remove(option.id)
                    } else {
                        if state.selectedOptionCodes.count < diagnosis.maxSelectCount {
                            state.selectedOptionCodes.insert(option.id)
                        }
                    }
                }
                return .none
                
            case .confirmButtonTapped:
                guard let diagnosis = state.currentDiagnosis,
                      diagnosis.selectType == .multi,
                      state.isConfirmButtonEnabled,
                      !state.isAnswerSaving else { return .none }
                
                let userText = diagnosis.options
                    .filter { state.selectedOptionCodes.contains($0.id) }
                    .map(\.title)
                    .joined(separator: ", ")
                
                state.history.append(.user(id: UUID(), text: userText))

                let selectedCodes = diagnosis.options
                    .map(\.id)
                    .filter { state.selectedOptionCodes.contains($0) }
                let answer = DiagnosisAnswer.multiple(field: diagnosis.field, codes: selectedCodes)

                state.isAnswerSaving = true
                return .run { send in
                    await send(.flowResponse(Result {
                        try await advanceDiagnosisFlowUseCase.execute(answer)
                    }))
                }

            case let .budgetMinimumChanged(minimum):
                state.budgetRange.updateMinimum(minimum, bounds: MapFilterPriceRange.monthlyRent)
                return .none

            case let .budgetMaximumChanged(maximum):
                state.budgetRange.updateMaximum(maximum, bounds: MapFilterPriceRange.monthlyRent)
                return .none

            case .budgetConfirmButtonTapped:
                guard let diagnosis = state.currentDiagnosis,
                      diagnosis.selectType == .slider,
                      !state.isAnswerSaving else { return .none }

                state.history.append(.user(id: UUID(), text: state.budgetAnswerText))
                state.isAnswerSaving = true

                let answer = DiagnosisAnswer.monthlyRent(
                    field: diagnosis.field,
                    min: state.budgetRange.minimum * 10_000,
                    max: state.budgetRange.maximum * 10_000
                )
                return .run { send in
                    await send(.flowResponse(Result {
                        try await advanceDiagnosisFlowUseCase.execute(answer)
                    }))
                }
                
            case .findButtonTapped:
                guard let diagnosisID = state.completedDiagnosisID else { return .none }
                let request = Int(diagnosisID)
                    .map(MapEntryRequest.diagnosis(id:))
                    ?? .browseListings
                return .send(.mapRequested(request))
                
            case .resetButtonTapped:
                state.resetConversation()
                return .send(.onAppear)

            case .mapRequested:
                return .none
            }
        }
    }
}

private extension ChatBotFeature.State {
    var isNextBotMessageFirst: Bool {
        guard let lastItem = history.last else { return true }

        if case .bot = lastItem {
            return false
        }

        return true
    }

    mutating func resetConversation() {
        currentStep = 1
        history.removeAll()
        currentQuestion = nil
        selectedOptionCodes.removeAll()
        budgetRange = Self.defaultBudgetRange
        completedDiagnosisID = nil
        isQuestionLoading = false
        isAnswerSaving = false
    }
}
