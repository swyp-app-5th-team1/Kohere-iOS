//
//  DiagnosisRepository.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import ComposableArchitecture
import Foundation

final class DiagnosisRepository: DiagnosisInterface {
    private let networkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        networkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.networkService = networkService
        self.environmentProvider = environmentProvider
    }

    func startFlow() async throws -> DiagnosisFlowResult {
        let environment = try environmentProvider()
        let responseDTO: DiagnosisFlowResponseDTO = try await networkService.request(
            DiagnosisRouter.startFlow(environment: environment)
        )

        return try responseDTO.toEntity()
    }

    func advanceFlow(with answer: DiagnosisAnswer) async throws -> DiagnosisFlowResult {
        let environment = try environmentProvider()
        let requestDTO = DiagnosisAnswerRequestDTO(answer)
        let responseDTO: DiagnosisFlowResponseDTO = try await networkService.request(
            DiagnosisRouter.advanceFlow(requestDTO, environment: environment)
        )

        return try responseDTO.toEntity()
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

	func fetchDetail(diagnosisID: Int) async throws -> DiagnosisDetail {
        let environment = try environmentProvider()
        let responseDTO: DiagnosisDetailResponseDTO = try await networkService.request(
            DiagnosisRouter.detail(diagnosisID: diagnosisID, environment)
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

	func fetchRecommendations(input: DiagnosisRecommendationsInput) async throws -> DiagnosisRecommendations {
        let environment = try environmentProvider()
        let queryDTO = DiagnosisRecommendationsQueryDTO(input)
        let responseDTO: DiagnosisRecommendationsResponseDTO = try await networkService.request(
            DiagnosisRouter.recommendations(
                diagnosisID: input.diagnosisID,
                query: queryDTO,
                environment
            ),
            debugRawJSONLabel: "DiagnosisRecommendations"
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
            question: question.replacingOccurrences(of: "\\n", with: "\n"),
            selectType: select.type.toSelectType(),
            maxSelectCount: select.max ?? 1,
            options: options.map { $0.toEntity() }
        )
    }
}

private extension DiagnosisFlowResponseDTO {
    func toEntity() throws -> DiagnosisFlowResult {
        switch resultCode {
        case "NEXT_QUESTION":
            guard let question else { throw DataError.decodingFailed }
            return .nextQuestion(question.toEntity())

        case "RESTART":
            return .restart

        case "TERMINATED":
            return .terminated

        case "COMPLETED":
            guard let diagnosisId else { throw DataError.decodingFailed }
            return .completed(diagnosisID: String(diagnosisId))

        default:
            throw DataError.decodingFailed
        }
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

private extension DiagnosisDetailResponseDTO {
    func toEntity() -> DiagnosisDetail {
        DiagnosisDetail(
            diagnosisID: diagnosisId,
            region: region,
            purpose: purpose,
            university: university,
            district: district,
            conditions: conditions.compactMap(RoomCondition.init(conditionCode:)),
            monthlyRentMin: monthlyRentMin,
            monthlyRentMax: monthlyRentMax,
            arcStatus: arcStatus,
            status: status,
            submittedAt: submittedAt
        )
    }
}

private extension DiagnosisRecommendationsResponseDTO {
    func toEntity() -> DiagnosisRecommendations {
        return DiagnosisRecommendations(
            listings: (content ?? []).map { $0.toEntity() },
            page: page?.toEntity(),
            suggestions: suggestions?.toEntity()
        )
    }
}

private extension DiagnosisRecommendedListingResponseDTO {
    func toEntity() -> DiagnosisRecommendedListing {
        let propertyTypeCode = type?.code ?? ""
        let propertyTypeLabel = type?.label ?? ""

        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return DiagnosisRecommendedListing(
            listingID: listingId,
            title: title ?? "",
            type: propertyTypeLabel,
            minMonthlyRent: monthlyRentMin,
            maxMonthlyRent: monthlyRentMax,
            minDeposit: minDeposit,
            maxDeposit: maxDeposit,
            thumbnailURL: nonEmptyThumbnailURL
                ?? MockListingImageProvider.listingImageName(
                    listingID: listingId,
                    propertyType: propertyTypeCode
                ),
            coordinate: coordinate
        )
    }

    private var nonEmptyThumbnailURL: String? {
        let trimmedURL = thumbnailUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedURL?.isEmpty == false ? trimmedURL : nil
    }
}

private extension DiagnosisRecommendationPageResponseDTO {
    func toEntity() -> DiagnosisRecommendationPage {
        DiagnosisRecommendationPage(
            number: number,
            size: size,
            totalElements: totalElements,
            totalPages: totalPages,
            hasNext: hasNext
        )
    }
}

private extension DiagnosisSuggestionsResponseDTO {
    func toEntity() -> DiagnosisRecommendationSuggestions {
        DiagnosisRecommendationSuggestions(
            reason: reason,
            message: message,
            actions: (actions ?? []).map { $0.toEntity() }
        )
    }
}

private extension DiagnosisSuggestionActionResponseDTO {
    func toEntity() -> DiagnosisRecommendationSuggestionAction {
        DiagnosisRecommendationSuggestionAction(
            type: type,
            detail: detail
        )
    }
}
