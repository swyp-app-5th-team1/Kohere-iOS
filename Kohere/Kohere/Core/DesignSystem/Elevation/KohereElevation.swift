//
//  KohereElevation.swift
//  Kohere
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

enum KohereElevation: CaseIterable {
    case normalXSmall
    case normalSmall
    case normalMedium
    case normalLarge
    case normalXLarge
    case spreadSmall
    case spreadMedium
    case bottomSheet

    var tokenName: String {
        switch self {
        case .normalXSmall: "shadow-normal-xsmall"
        case .normalSmall: "shadow-normal-small"
        case .normalMedium: "shadow-normal-medium"
        case .normalLarge: "shadow-normal-large"
        case .normalXLarge: "shadow-normal-xlarge"
        case .spreadSmall: "shadow-spread-small"
        case .spreadMedium: "shadow-spread-medium"
        case .bottomSheet: "shadow-bottom-sheet"
        }
    }

    var layers: [KohereShadowLayer] {
        switch self {
        case .normalXSmall:
            [
                .init(x: 0, y: 1, blur: 2, spread: -1, red: 23, green: 23, blue: 23, opacity: 0.1)
            ]
        case .normalSmall:
            [
                .init(x: 0, y: 4, blur: 6, spread: -1, red: 23, green: 23, blue: 23, opacity: 0.06),
                .init(x: 0, y: 2, blur: 4, spread: -2, red: 23, green: 23, blue: 23, opacity: 0.06)
            ]
        case .normalMedium:
            [
                .init(x: 0, y: 10, blur: 15, spread: -3, red: 23, green: 23, blue: 23, opacity: 0.07),
                .init(x: 0, y: 4, blur: 6, spread: -2, red: 0, green: 0, blue: 0, opacity: 0.07)
            ]
        case .normalLarge:
            [
                .init(x: 0, y: 16, blur: 24, spread: -6, red: 23, green: 23, blue: 23, opacity: 0.08),
                .init(x: 0, y: 6, blur: 10, spread: -4, red: 23, green: 23, blue: 23, opacity: 0.08)
            ]
        case .normalXLarge:
            [
                .init(x: 0, y: 24, blur: 36, spread: -10, red: 23, green: 23, blue: 23, opacity: 0.12),
                .init(x: 0, y: 10, blur: 16, spread: -4, red: 23, green: 23, blue: 23, opacity: 0.1)
            ]
        case .spreadSmall:
            [
                .init(x: 0, y: 0, blur: 60, spread: 0, red: 23, green: 23, blue: 23, opacity: 0.1)
            ]
        case .spreadMedium:
            [
                .init(x: 0, y: 16, blur: 72, spread: 0, red: 23, green: 23, blue: 23, opacity: 0.16)
            ]
        case .bottomSheet:
            [
                .init(x: 0, y: -1, blur: 2, spread: -1, red: 23, green: 23, blue: 23, opacity: 0.1)
            ]
        }
    }
}

struct KohereShadowLayer {
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat
    let color: Color

    init(
        x: CGFloat,
        y: CGFloat,
        blur: CGFloat,
        spread: CGFloat,
        red: Double,
        green: Double,
        blue: Double,
        opacity: Double
    ) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        color = Color(red: red / 255, green: green / 255, blue: blue / 255, opacity: opacity)
    }
}
