//
//  BaseResponseDTO.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

struct BaseResponseDTO<Data: Decodable>: Decodable {
    let success: Bool
    let data: Data?
    let error: APIErrorDTO?
}

struct APIErrorDTO: Decodable, Equatable {
    let code: String
    let message: String
    let errors: [APIFieldErrorDTO]
}

struct APIFieldErrorDTO: Decodable, Equatable {
    let field: String
    let reason: String
}
