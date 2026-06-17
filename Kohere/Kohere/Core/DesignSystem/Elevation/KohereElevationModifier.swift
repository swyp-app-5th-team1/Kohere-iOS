//
//  KohereElevationModifier.swift
//  Kohere
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

private struct KohereElevationModifier: ViewModifier {
    let elevation: KohereElevation
    let shadowShape: KohereShadowShape

    func body(content: Content) -> some View {
        content
            .background {
                KohereElevationShadow(elevation: elevation, shadowShape: shadowShape)
            }
    }
}

private struct KohereSurfaceModifier: ViewModifier {
    let backgroundColor: Color
    let shadowShape: KohereShadowShape
    let elevation: KohereElevation

    func body(content: Content) -> some View {
        let shape = shadowShape.shape

        content
            .background {
                shape.fill(backgroundColor)
            }
            .clipShape(shape)
            .background {
                KohereElevationShadow(elevation: elevation, shadowShape: shadowShape)
            }
    }
}

private struct KohereElevationShadow: View {
    let elevation: KohereElevation
    let shadowShape: KohereShadowShape

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                ForEach(Array(elevation.layers.enumerated()), id: \.offset) { _, layer in
                    let width = max(size.width + layer.spread * 2, 0)
                    let height = max(size.height + layer.spread * 2, 0)

                    shadowShape.shape
                        .fill(layer.color)
                        .frame(width: width, height: height)
                        .blur(radius: layer.blur)
                        .position(
                            x: size.width / 2 + layer.x,
                            y: size.height / 2 + layer.y
                        )
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func kohereElevation(_ elevation: KohereElevation, shape: KohereShadowShape) -> some View {
        modifier(KohereElevationModifier(elevation: elevation, shadowShape: shape))
    }

    func kohereSurface(
        background: Color,
        shape: KohereShadowShape,
        elevation: KohereElevation
    ) -> some View {
        modifier(
            KohereSurfaceModifier(
                backgroundColor: background,
                shadowShape: shape,
                elevation: elevation
            )
        )
    }
}
