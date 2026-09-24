//
//  LivingGuideRepository.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

import ComposableArchitecture

// MARK: - Repository

final class LivingGuideRepository: LivingGuideInterface {
    private let authenticatedNetworkService: NetworkService
    private let environmentProvider: () throws -> APIEnvironment

    init(
        authenticatedNetworkService: NetworkService = LiveNetworkServiceFactory.authenticated(),
        environmentProvider: @escaping () throws -> APIEnvironment = { try APIEnvironment.live() }
    ) {
        self.authenticatedNetworkService = authenticatedNetworkService
        self.environmentProvider = environmentProvider
    }

    func fetchTopics() async throws -> [LivingGuide] {
        let environment = try environmentProvider()
        let responseDTO: LivingGuideTopicsResponseDTO = try await authenticatedNetworkService.request(
            LivingGuideRouter.topics(environment)
        )

        return (responseDTO.topics ?? []).enumerated().compactMap { index, topicDTO in
            topicDTO.toEntity(index: index)
        }
    }

    func fetchTips(topicCode: String) async throws -> [LivingGuideTip] {
        let environment = try environmentProvider()
        let responseDTO: LivingGuideListResponseDTO = try await authenticatedNetworkService.request(
            LivingGuideRouter.tips(topicCode: topicCode, environment)
        )

        return (responseDTO.tips ?? []).enumerated().compactMap { index, tipDTO in
            tipDTO.toEntity(index: index)
        }
    }
}

// MARK: - Dependency

extension LivingGuideClient: DependencyKey {
    static let liveValue: LivingGuideClient = {
        let repository: any LivingGuideInterface = LivingGuideRepository()
        return LivingGuideClient(repository: repository)
    }()
}

// MARK: - Mapper

private extension LivingGuideTopicResponseDTO {
    func toEntity(index: Int) -> LivingGuide? {
        guard let code, let name else { return nil }

        let theme = LivingGuideTheme.theme(for: code, index: index)

        return LivingGuide(
            id: index + 1,
            code: code,
            name: name,
            shortDescription: shortDescription ?? "",
            longDescription: longDescription ?? "",
            iconName: theme.iconName,
            theme: theme
        )
    }
}

private extension LivingGuideTipResponseDTO {
    func toEntity(index: Int) -> LivingGuideTip? {
        guard let id, let title, let content else { return nil }

        return LivingGuideTip(
            id: id,
            title: title,
            content: content,
            imageURL: imageUrl
        )
    }
}

private extension LivingGuideTheme {
    static func theme(for code: String, index: Int) -> LivingGuideTheme {
        switch code {
        case "HOUSING_SCAM", "HOUSING_SCAMS", "MOVING_IN":
            .housingScams

        case "BANK", "BANK_ACCOUNT":
            .bankAccount

        case "TRANSPORT":
            .publicTransit

        case "HEALTH", "HEALTH_INSURANCE":
            .healthInsurance

        default:
            fallbackTheme(for: index)
        }
    }

    static func fallbackTheme(for index: Int) -> LivingGuideTheme {
        switch index % 4 {
        case 0:
            .housingScams

        case 1:
            .bankAccount

        case 2:
            .publicTransit

        default:
            .healthInsurance
        }
    }

    var iconName: String {
        switch self {
        case .housingScams:
            "contractChecklist"

        case .bankAccount:
            "bankAccountGuide"

        case .publicTransit:
            "train"

        case .healthInsurance:
            "healthInsurance"
        }
    }
}
