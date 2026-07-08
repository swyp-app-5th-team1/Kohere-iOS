//
//  LifeTipResponseDTO.swift
//  Kohere
//
//  Created by mandoo on 7/8/26.
//

// MARK: - Response

struct LifeTipTopicsResponseDTO: Decodable {
    let topics: [LifeTipTopicResponseDTO]?
}

struct LifeTipTopicResponseDTO: Decodable {
    let code: String?
    let name: String?
}

struct LifeTipListResponseDTO: Decodable {
    let tips: [LifeTipResponseDTO]?
}

struct LifeTipResponseDTO: Decodable {
    let id: String?
    let title: String?
    let content: String?
    let imageUrl: String?
}
