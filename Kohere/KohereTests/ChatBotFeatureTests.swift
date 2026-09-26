//
//  ChatBotFeatureTests.swift
//  KohereTests
//
//  Created by Codex on 9/26/26.
//

import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class ChatBotFeatureTests: XCTestCase {
    func testOnAppearStartsDiagnosisFlow() async {
        let question = diagnosis(
            step: 1,
            field: "REGION",
            selectType: .single,
            options: [DiagnosisOption(id: "SEOUL", title: "Seoul")]
        )
        let messageID = UUID()
        let store = TestStore(initialState: ChatBotFeature.State()) {
            ChatBotFeature()
        } withDependencies: {
            $0.uuid = .constant(messageID)
            $0.startDiagnosisFlowUseCase = StartDiagnosisFlowUseCase {
                .nextQuestion(question)
            }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.flowResponse)

        XCTAssertEqual(store.state.currentQuestion, question)
        XCTAssertEqual(store.state.history, [
            .bot(id: messageID, text: "Welcome 👋", isFirst: true),
            .bot(id: messageID, text: question.question, isFirst: false)
        ])
    }

    func testSingleOptionAdvancesFlowAndUpdatesFilter() async {
        let option = DiagnosisOption(id: "PRIVATE_BATH", title: "Private bathroom")
        let question = diagnosis(step: 2, field: "CONDITION", selectType: .single, options: [option])
        var state = ChatBotFeature.State()
        state.currentQuestion = question
        let receivedAnswer = LockIsolated<DiagnosisAnswer?>(nil)
        let store = TestStore(initialState: state) {
            ChatBotFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID())
            $0.advanceDiagnosisFlowUseCase = AdvanceDiagnosisFlowUseCase { answer in
                receivedAnswer.setValue(answer)
                return .completed(diagnosisID: 42)
            }
        }
        store.exhaustivity = .off

        await store.send(.optionTapped(option))
        XCTAssertTrue(store.state.isSubmittingAnswer)
        XCTAssertEqual(store.state.diagnosisFilter.selectedOptions, [.privateBathroom])

        await store.receive(\.flowResponse)
        XCTAssertEqual(receivedAnswer.value, .single(field: "CONDITION", code: "PRIVATE_BATH"))
        XCTAssertEqual(store.state.completedDiagnosisID, 42)
        XCTAssertFalse(store.state.isSubmittingAnswer)
    }

    func testMultiSelectRespectsMaximumAndKeepsQuestionOrder() async {
        let first = DiagnosisOption(id: "PRIVATE_BATH", title: "Private bathroom")
        let second = DiagnosisOption(id: "FEMALE_ONLY", title: "Female only")
        let third = DiagnosisOption(id: "MEAL_INCLUDED", title: "Meals included")
        let question = diagnosis(
            step: 4,
            field: "CONDITION",
            selectType: .multi,
            maxSelectCount: 2,
            options: [first, second, third]
        )
        var state = ChatBotFeature.State()
        state.currentQuestion = question
        let receivedAnswer = LockIsolated<DiagnosisAnswer?>(nil)
        let store = TestStore(initialState: state) {
            ChatBotFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID())
            $0.advanceDiagnosisFlowUseCase = AdvanceDiagnosisFlowUseCase { answer in
                receivedAnswer.setValue(answer)
                return .completed(diagnosisID: 42)
            }
        }
        store.exhaustivity = .off

        await store.send(.optionTapped(second))
        await store.send(.optionTapped(first))
        await store.send(.optionTapped(third))

        XCTAssertEqual(store.state.selectedOptionCodes, [first.id, second.id])
        XCTAssertEqual(store.state.disabledMultiSelectOptionCodes, [third.id])

        await store.send(.confirmButtonTapped)
        await store.receive(\.flowResponse)

        XCTAssertEqual(receivedAnswer.value, .multiple(field: "CONDITION", codes: [first.id, second.id]))
        XCTAssertEqual(store.state.diagnosisFilter.selectedOptions, [.privateBathroom, .femaleOnly])
    }

    func testCompletedDiagnosisRequestsMapWithCollectedFilter() async {
        var state = ChatBotFeature.State()
        state.completedDiagnosisID = 42
        state.diagnosisFilter.selectedOptions = [.privateBathroom]
        let store = TestStore(initialState: state) {
            ChatBotFeature()
        }

        await store.send(.findButtonTapped)
        await store.receive(.delegate(.mapRequested(.diagnosis(id: 42, filter: state.diagnosisFilter))))
    }

    func testBackButtonRequestsDismissal() async {
        let store = TestStore(initialState: ChatBotFeature.State()) {
            ChatBotFeature()
        }

        await store.send(.backButtonTapped)
        await store.receive(\.delegate.dismissRequested)
    }

    private func diagnosis(
        step: Int,
        field: String,
        selectType: SelectType,
        maxSelectCount: Int = 1,
        options: [DiagnosisOption]
    ) -> Diagnosis {
        Diagnosis(
            step: step,
            field: field,
            question: "Question \(step)",
            selectType: selectType,
            maxSelectCount: maxSelectCount,
            options: options
        )
    }
}
