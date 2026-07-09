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
        networkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
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
        let listingEntities = (content ?? []).map { $0.toEntity() }
        let markerEntities = (markers ?? []).compactMap { $0.toEntity() }
        let fallbackMarkers = listingEntities.compactMap { listing -> MapMarkerItem? in
            guard let coordinate = listing.coordinate else { return nil }
            return MapMarkerItem(id: listing.listingID, coordinate: coordinate)
        }

        return DiagnosisRecommendations(
            listings: listingEntities,
            markers: markerEntities.isEmpty ? fallbackMarkers : markerEntities,
            page: page?.toEntity(),
            suggestions: suggestions?.toEntity()
        )
    }
}

private extension DiagnosisRecommendedListingResponseDTO {
    func toEntity() -> DiagnosisRecommendedListing {
        let coordinate: MapCoordinate?
        if let lat, let lng {
            coordinate = MapCoordinate(latitude: lat, longitude: lng)
        } else {
            coordinate = nil
        }

        return DiagnosisRecommendedListing(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            minMonthlyRent: monthlyRentMin,
            maxMonthlyRent: monthlyRentMax,
            minDeposit: minDeposit,
            maxDeposit: maxDeposit,
            thumbnailURL: thumbnailUrl,
            coordinate: coordinate,
            conditions: (conditions ?? []).compactMap(RoomCondition.init(conditionCode:))
        )
    }
}

private extension DiagnosisRecommendationMarkerResponseDTO {
    func toEntity() -> MapMarkerItem? {
        guard let lat, let lng else { return nil }
        return MapMarkerItem(
            id: listingId,
            coordinate: MapCoordinate(latitude: lat, longitude: lng)
        )
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
