//
//  KohereShadowShape.swift
//  Kohere
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

enum KohereShadowShape {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case circle
    case capsule

    var shape: KohereAnyShape {
        switch self {
        case .rectangle:
            KohereAnyShape(Rectangle())
        case let .roundedRectangle(cornerRadius):
            KohereAnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .circle:
            KohereAnyShape(Circle())
        case .capsule:
            KohereAnyShape(Capsule())
        }
    }
}

struct KohereAnyShape: Shape {
    private let makePath: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        makePath = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        makePath(rect)
    }
}
