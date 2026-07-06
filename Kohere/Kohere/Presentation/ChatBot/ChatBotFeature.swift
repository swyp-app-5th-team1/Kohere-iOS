import ComposableArchitecture
import Foundation

@Reducer
struct ChatBotFeature {
    @Dependency(\.fetchDiagnosisQuestionUseCase)
    var fetchDiagnosisQuestionUseCase
    @Dependency(\.saveDiagnosisAnswerUseCase)
    var saveDiagnosisAnswerUseCase
    @Dependency(\.submitDiagnosisUseCase)
    var submitDiagnosisUseCase

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
        var isUnsupportedRegionConfirmationPresented = false
        var isQuestionLoading = false
        var isAnswerSaving = false
        var isSubmitting = false
        
        var currentDiagnosis: Diagnosis? {
            if isUnsupportedRegionConfirmationPresented {
                return Self.unsupportedRegionConfirmation
            }

            return currentQuestion
        }
        
        var isConfirmButtonEnabled: Bool {
            guard let maxCount = currentDiagnosis?.maxSelectCount else { return false }
            return !selectedOptionCodes.isEmpty && selectedOptionCodes.count <= maxCount
        }
        
        var isFindButtonEnabled: Bool {
            return currentStep >= 7
        }

        var budgetSummaryText: String {
            let bounds = MapFilterPriceRange.monthlyRent

            switch (budgetRange.minimum, budgetRange.maximum) {
            case (bounds.lowerBound, bounds.upperBound):
                return "Any"
            case (bounds.lowerBound, let maximum):
                return "Under \(Self.budgetPriceText(maximum))"
            case (let minimum, bounds.upperBound):
                return "\(Self.budgetPriceText(minimum))+"
            case let (minimum, maximum):
                return "\(Self.budgetPriceText(minimum)) ~ \(Self.budgetPriceText(maximum))"
            }
        }

        var budgetAnswerText: String {
            "\(budgetRange.minimum)~\(budgetRange.maximum)만원"
        }

        static let defaultBudgetRange = RangeSliderValue(
            minimum: MapFilterPriceRange.monthlyRent.lowerBound,
            maximum: 50,
            bounds: MapFilterPriceRange.monthlyRent
        )

        static let unsupportedRegionConfirmation = Diagnosis(
            step: 0,
            field: "unsupportedRegionConfirmation",
            question: "다른 지역 방을 찾아보시겠어요?",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(id: "YES", title: "네"),
                DiagnosisOption(id: "NO", title: "아니오")
            ]
        )

        private static func budgetPriceText(_ value: Int) -> String {
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
        case questionResponse(Result<Diagnosis, Error>)
        case optionTapped(DiagnosisOption)
        case confirmButtonTapped
        case budgetMinimumChanged(Int)
        case budgetMaximumChanged(Int)
        case budgetConfirmButtonTapped
        case answerSaved(nextStep: Int, Result<Void, Error>)
        case findButtonTapped
        case submitResponse(Result<DiagnosisSubmission, Error>)
        case resetButtonTapped
        case mapTabRequested(diagnosisID: String?)
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
                    await send(.answerSaved(
                        nextStep: 2,
                        Result {
                            try await saveDiagnosisAnswerUseCase.execute(
                                .single(field: "region", code: "SEOUL")
                            )
                        }
                    ))
                }

            case let .questionResponse(.success(question)):
                state.isQuestionLoading = false
                state.currentStep = question.step
                state.currentQuestion = question
                state.history.append(.bot(
                    id: UUID(),
                    text: question.question,
                    isFirst: state.isNextBotMessageFirst
                ))
                return .none
                
            case .questionResponse(.failure):
                state.isQuestionLoading = false
                return .none

            case let .answerSaved(nextStep, .success):
                state.isAnswerSaving = false
                state.selectedOptionCodes.removeAll()
                state.currentQuestion = nil
                state.currentStep = nextStep

                guard nextStep <= 6 else {
                    return .none
                }

                state.isQuestionLoading = true
                return .run { send in
                    await send(.questionResponse(Result {
                        try await fetchDiagnosisQuestionUseCase.execute(nextStep)
                    }))
                }

            case .answerSaved(_, .failure):
                state.isAnswerSaving = false
                return .none
                
            case let .optionTapped(option):
                guard let diagnosis = state.currentDiagnosis, !state.isAnswerSaving else { return .none }

                if state.isUnsupportedRegionConfirmationPresented {
                    state.history.append(.user(id: UUID(), text: option.title))

                    switch option.id {
                    case "YES":
                        state.resetConversation()
                        return .send(.onAppear)

                    case "NO":
                        return .send(.mapTabRequested(diagnosisID: nil))

                    default:
                        return .none
                    }
                }
                
                if diagnosis.selectType == .single {
                    state.history.append(.user(id: UUID(), text: option.title))

                    if diagnosis.field == "region", option.id != "SEOUL" {
                        state.isUnsupportedRegionConfirmationPresented = true
                        state.appendUnsupportedRegionConfirmation(regionName: option.title)
                        return .none
                    }

                    state.isAnswerSaving = true
                    let nextStep = diagnosis.step + 1
                    let answer = DiagnosisAnswer.single(field: diagnosis.field, code: option.id)

                    return .run { send in
                        await send(.answerSaved(
                            nextStep: nextStep,
                            Result { try await saveDiagnosisAnswerUseCase.execute(answer) }
                        ))
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
                let nextStep = diagnosis.step + 1
                let answer = DiagnosisAnswer.multiple(field: diagnosis.field, codes: selectedCodes)

                state.isAnswerSaving = true
                return .run { send in
                    await send(.answerSaved(
                        nextStep: nextStep,
                        Result { try await saveDiagnosisAnswerUseCase.execute(answer) }
                    ))
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
                let nextStep = diagnosis.step + 1

                return .run { send in
                    await send(.answerSaved(
                        nextStep: nextStep,
                        Result { try await saveDiagnosisAnswerUseCase.execute(answer) }
                    ))
                }
                
            case .findButtonTapped:
                guard state.isFindButtonEnabled, !state.isSubmitting else { return .none }
                state.isSubmitting = true

                return .run { send in
                    await send(.submitResponse(Result {
                        try await submitDiagnosisUseCase.execute()
                    }))
                }

            case let .submitResponse(.success(submission)):
                state.isSubmitting = false
                return .send(.mapTabRequested(diagnosisID: submission.diagnosisID))

            case .submitResponse(.failure):
                state.isSubmitting = false
                return .none
                
            case .resetButtonTapped:
                state.resetConversation()
                return .send(.onAppear)

            case .mapTabRequested:
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
        isUnsupportedRegionConfirmationPresented = false
        isQuestionLoading = false
        isAnswerSaving = false
        isSubmitting = false
    }

    mutating func appendUnsupportedRegionConfirmation(regionName: String) {
        history.append(.bot(
            id: UUID(),
            text: "아직 \(regionName) 매물은 준비되지 않았어요😓",
            isFirst: true
        ))
        history.append(.bot(
            id: UUID(),
            text: Self.unsupportedRegionConfirmation.question,
            isFirst: false
        ))
    }
}
