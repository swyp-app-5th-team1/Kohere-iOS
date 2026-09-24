//
//  LivingGuideResponseDTO.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

// MARK: - Response

struct LivingGuideTopicsResponseDTO: Decodable {
    let topics: [LivingGuideTopicResponseDTO]?
}

struct LivingGuideTopicResponseDTO: Decodable {
    let code: String?
    let name: String?
    let shortDescription: String?
    let longDescription: String?
}

struct LivingGuideListResponseDTO: Decodable {
    let tips: [LivingGuideTipResponseDTO]?
}

struct LivingGuideTipResponseDTO: Decodable {
    let id: String?
    let title: String?
    let content: String?
    let imageUrl: String?
}
