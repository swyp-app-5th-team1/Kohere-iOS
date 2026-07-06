//
//  FrankfurterRateResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation

nonisolated struct FrankfurterRateResponseDTO: Decodable, Sendable {
    let rate: Decimal
}
