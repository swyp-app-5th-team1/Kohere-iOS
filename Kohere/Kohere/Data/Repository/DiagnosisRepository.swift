//
//  DiagnosisRepository.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture

final class DiagnosisRepository: DiagnosisInterface {
    private let networkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        networkService: NetworkService = .authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.networkService = networkService
        self.environmentProvider = environmentProvider
    }

    func fetchQuestion(step: Int) async throws -> Diagnosis {
        let environment = try environmentProvider()
        let responseDTO: DiagnosisQuestionResponseDTO = try await networkService.request(
            DiagnosisRouter.question(
                step: step,
                environment: environment
            )
        )

        return responseDTO.toEntity()
    }

    func saveAnswer(_ answer: DiagnosisAnswer) async throws {
        let environment = try environmentProvider()
        let requestDTO = DiagnosisAnswerRequestDTO(answer)

        try await networkService.requestVoid(
            DiagnosisRouter.saveAnswer(
                requestDTO,
                environment: environment
            )
        )
    }

    func submit() async throws -> DiagnosisSubmission {
        let environment = try environmentProvider()
        let responseDTO: DiagnosisSubmissionResponseDTO = try await networkService.request(
            DiagnosisRouter.submit(
                environment: environment
            )
        )

        return responseDTO.toEntity()
    }
}

extension DiagnosisClient: DependencyKey {
    static let liveValue: DiagnosisClient = {
        let repository: any DiagnosisInterface = DiagnosisRepository()
        return DiagnosisClient(repository: repository)
    }()
}

private extension DiagnosisAnswerRequestDTO {
    init(_ answer: DiagnosisAnswer) {
        switch answer {
        case let .single(field, code):
            self = .single(field: field, code: code)

        case let .multiple(field, codes):
            self = .multiple(field: field, codes: codes)

        case let .monthlyRent(field, min, max):
            self = .monthlyRent(field: field, min: min, max: max)
        }
    }
}

private extension DiagnosisQuestionResponseDTO {
    func toEntity() -> Diagnosis {
        Diagnosis(
            step: step,
            field: field,
            question: question,
            selectType: select.type.toSelectType(),
            maxSelectCount: select.max ?? 1,
            options: options.map { $0.toEntity() }
        )
    }
}

private extension DiagnosisOptionResponseDTO {
    func toEntity() -> DiagnosisOption {
        DiagnosisOption(id: code, title: label)
    }
}

private extension String {
    func toSelectType() -> SelectType {
        switch uppercased() {
        case "SINGLE":
            .single
        case "MULTI", "MULTIPLE":
            .multi
        case "SLIDER", "NUMBER_RANGE":
            .slider
        default:
            .single
        }
    }
}

private extension DiagnosisSubmissionResponseDTO {
    func toEntity() -> DiagnosisSubmission {
        DiagnosisSubmission(
            diagnosisID: String(diagnosisId),
            status: status,
            submittedAt: submittedAt
        )
    }
}
