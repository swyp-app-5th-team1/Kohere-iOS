import ComposableArchitecture
import Foundation

@Reducer
struct ChatBotFeature {
    @Dependency(\.startDiagnosisFlowUseCase)
    var startDiagnosisFlowUseCase
    @Dependency(\.advanceDiagnosisFlowUseCase)
    var advanceDiagnosisFlowUseCase
    @Dependency(\.uuid)
    var uuid

    private nonisolated enum EffectID {
        case diagnosisFlow
    }

    enum ChatItem: Equatable, Identifiable {
        case bot(id: UUID, text: String, isFirst: Bool)
        case user(id: UUID, text: String)
        
        var id: UUID {
            switch self {
            case .bot(let id, _, _): return id
            case .user(let id, _): return id
            }
        }

        var isBot: Bool {
            if case .bot = self { return true }
            return false
        }
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var history: [ChatItem] = []
        var currentQuestion: Diagnosis?
        var selectedOptionCodes: Set<String> = []
        var budgetRange = Self.defaultBudgetRange
        var diagnosisFilter = MapFilterState()
        var completedDiagnosisID: Int?
        var isSubmittingAnswer = false
        
        var isConfirmButtonEnabled: Bool {
            guard let maxCount = currentQuestion?.maxSelectCount else { return false }
            return !selectedOptionCodes.isEmpty && selectedOptionCodes.count <= maxCount
        }

        var disabledMultiSelectOptionCodes: Set<String> {
            guard let diagnosis = currentQuestion else { return [] }
            if isSubmittingAnswer { return Set(diagnosis.options.map(\.id)) }
            guard selectedOptionCodes.count >= diagnosis.maxSelectCount else { return [] }
            return Set(diagnosis.options.map(\.id)).subtracting(selectedOptionCodes)
        }
        
        var isFindButtonEnabled: Bool {
            completedDiagnosisID != nil
        }

        func budgetAnswerText(language: AppLanguage) -> String {
            language.localized(
                .chatBotBudgetRange(
                    MapFilterPriceFormatter.amountText(budgetRange.minimum, locale: language.locale),
                    MapFilterPriceFormatter.amountText(budgetRange.maximum, locale: language.locale)
                )
            )
        }

        static let defaultBudgetRange = RangeSliderValue(
            minimum: MapFilterPriceRange.monthlyRent.lowerBound,
            maximum: 50,
            bounds: MapFilterPriceRange.monthlyRent
        )
    }
    
    // MARK: - Action
    
    @CasePathable
    enum Delegate: Equatable {
        case dismissRequested
        case mapRequested(MapEntryRequest)
    }

    enum Action: Equatable {
        case backButtonTapped
        case onAppear
        case flowResponse(Result<DiagnosisFlowResult, DataError>)
        case optionTapped(DiagnosisOption)
        case confirmButtonTapped
        case budgetMinimumChanged(Int)
        case budgetMaximumChanged(Int)
        case budgetConfirmButtonTapped(AppLanguage)
        case findButtonTapped
        case resetButtonTapped
        case delegate(Delegate)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.dismissRequested))
                
            case .onAppear:
                guard state.history.isEmpty else { return .none }

                state.history.append(.bot(id: uuid(), text: "Welcome 👋", isFirst: true))
                return startDiagnosisFlow()

            case let .flowResponse(.success(.nextQuestion(question))):
                state.isSubmittingAnswer = false
                state.selectedOptionCodes.removeAll()
                state.currentQuestion = question
                state.history.append(.bot(
                    id: uuid(),
                    text: question.question,
                    isFirst: state.isNextBotMessageFirst
                ))
                return .none

            case .flowResponse(.success(.restart)):
                state.resetConversation()
                return .send(.onAppear)

            case .flowResponse(.success(.terminated)):
                state.isSubmittingAnswer = false
                return .send(.delegate(.dismissRequested))

            case let .flowResponse(.success(.completed(diagnosisID))):
                state.isSubmittingAnswer = false
                state.selectedOptionCodes.removeAll()
                state.currentQuestion = nil
                state.completedDiagnosisID = diagnosisID
                return .none

            case let .flowResponse(.failure(error)):
                state.isSubmittingAnswer = false

                if case let DataError.serverError(code, _) = error,
                   code == "DIAGNOSIS_SESSION_NOT_FOUND" {
                    state.resetConversation()
                    return .send(.onAppear)
                }

                return .none
                
            case let .optionTapped(option):
                guard let diagnosis = state.currentQuestion, !state.isSubmittingAnswer else { return .none }
                
                if diagnosis.selectType == .single {
                    state.history.append(.user(id: uuid(), text: option.title))

                    if let condition = RoomCondition(conditionCode: option.id) {
                        state.diagnosisFilter.selectedOptions.insert(condition)
                    }

                    state.isSubmittingAnswer = true
                    let answer = DiagnosisAnswer.single(field: diagnosis.field, code: option.id)
                    return advanceDiagnosisFlow(with: answer)
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
                guard let diagnosis = state.currentQuestion,
                      diagnosis.selectType == .multi,
                      state.isConfirmButtonEnabled,
                      !state.isSubmittingAnswer else { return .none }
                
                let userText = diagnosis.options
                    .filter { state.selectedOptionCodes.contains($0.id) }
                    .map(\.title)
                    .joined(separator: ", ")
                
                state.history.append(.user(id: uuid(), text: userText))

                let selectedCodes = diagnosis.options
                    .map(\.id)
                    .filter { state.selectedOptionCodes.contains($0) }
                let answer = DiagnosisAnswer.multiple(field: diagnosis.field, codes: selectedCodes)

                state.diagnosisFilter.selectedOptions.formUnion(
                    selectedCodes.compactMap(RoomCondition.init(conditionCode:))
                )

                state.isSubmittingAnswer = true
                return advanceDiagnosisFlow(with: answer)

            case let .budgetMinimumChanged(minimum):
                state.budgetRange.updateMinimum(minimum, bounds: MapFilterPriceRange.monthlyRent)
                return .none

            case let .budgetMaximumChanged(maximum):
                state.budgetRange.updateMaximum(maximum, bounds: MapFilterPriceRange.monthlyRent)
                return .none

            case let .budgetConfirmButtonTapped(language):
                guard let diagnosis = state.currentQuestion,
                      diagnosis.selectType == .slider,
                      !state.isSubmittingAnswer else { return .none }

                state.history.append(.user(
                    id: uuid(),
                    text: state.budgetAnswerText(language: language)
                ))
                state.isSubmittingAnswer = true
                state.diagnosisFilter.monthlyRentRange = state.budgetRange

                let answer = DiagnosisAnswer.monthlyRent(
                    field: diagnosis.field,
                    min: state.budgetRange.minimum * 10_000,
                    max: state.budgetRange.maximum * 10_000
                )
                return advanceDiagnosisFlow(with: answer)
                
            case .findButtonTapped:
                guard let diagnosisID = state.completedDiagnosisID else { return .none }
                let request = MapEntryRequest.diagnosis(id: diagnosisID, filter: state.diagnosisFilter)
                return .send(.delegate(.mapRequested(request)))
                
            case .resetButtonTapped:
                state.resetConversation()
                return .send(.onAppear)

            case .delegate:
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
        history.removeAll()
        currentQuestion = nil
        selectedOptionCodes.removeAll()
        budgetRange = Self.defaultBudgetRange
        diagnosisFilter = MapFilterState()
        completedDiagnosisID = nil
        isSubmittingAnswer = false
    }
}

private extension ChatBotFeature {
    func startDiagnosisFlow() -> Effect<Action> {
        .run { [startDiagnosisFlowUseCase] send in
            do {
                await send(.flowResponse(.success(try await startDiagnosisFlowUseCase.execute())))
            } catch {
                await send(.flowResponse(.failure(.from(error))))
            }
        }
        .cancellable(id: EffectID.diagnosisFlow, cancelInFlight: true)
    }

    func advanceDiagnosisFlow(with answer: DiagnosisAnswer) -> Effect<Action> {
        .run { [advanceDiagnosisFlowUseCase] send in
            do {
                await send(.flowResponse(.success(try await advanceDiagnosisFlowUseCase.execute(answer))))
            } catch {
                await send(.flowResponse(.failure(.from(error))))
            }
        }
        .cancellable(id: EffectID.diagnosisFlow, cancelInFlight: true)
    }
}
