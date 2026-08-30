//
//  CreateChatInquiryUseCase.swift
//  Kohere
//

import ComposableArchitecture

struct CreateChatInquiryUseCase {
    var execute: (_ listingID: String) async throws -> ChatInquiry
}

extension CreateChatInquiryUseCase: DependencyKey {
    static let liveValue: CreateChatInquiryUseCase = {
        @Dependency(\.chatClient)
        var chatClient

        return CreateChatInquiryUseCase { listingID in
            try await chatClient.createInquiry(listingID)
        }
    }()
}

extension DependencyValues {
    var createChatInquiryUseCase: CreateChatInquiryUseCase {
        get { self[CreateChatInquiryUseCase.self] }
        set { self[CreateChatInquiryUseCase.self] = newValue }
    }
}
