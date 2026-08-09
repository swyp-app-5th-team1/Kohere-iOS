//
//  MapDiagnosisButton.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

struct MapDiagnosisButton: View {
    enum Variant: Equatable {
        case discovery
        case matches
    }

    let variant: Variant
    let isExpanded: Bool
    let action: () -> Void
    let closeAction: () -> Void

    @Namespace private var animationNamespace

    var body: some View {
        content
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: isExpanded)
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: variant)
    }

    @ViewBuilder private var content: some View {
        if isExpanded {
            expandedContent
        } else {
            collapsedContent
        }
    }

    @ViewBuilder private var expandedContent: some View {
        switch variant {
        case .discovery:
            Button(action: action) {
                discoveryExpandedContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.mapDiagnosisAccessibilityCollapsed))

        case .matches:
            matchesExpandedContent
        }
    }

    private var discoveryExpandedContent: some View {
        HStack(spacing: 4) {
            sparkleIcon(color: .secondary5)

            VStack(alignment: .leading, spacing: 0) {
                Text(.mapDiagnosisTitle)
                    .kohereTextStyle(.label3Semibold)

                Text(.mapDiagnosisStartButton)
                    .kohereTextStyle(.caption2Regular)
            }
            .foregroundStyle(.secondary5)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .diagnosisButtonBackground(.gradient, in: animationNamespace)
    }

    private var matchesExpandedContent: some View {
        HStack(spacing: 8) {
            Button(action: action) {
                HStack(spacing: 4) {
                    sparkleIcon(color: .primary50)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(.mapDiagnosisMatchesTitle)
                            .kohereTextStyle(.label3Semibold)

                        Text(.mapDiagnosisTryAgain)
                            .kohereTextStyle(.caption2Regular)
                    }
                    .foregroundStyle(.primary50)
                    .fixedSize()
                }
            }

            Button(action: closeAction) {
                Image(.close16)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.primary50)
                    .frame(width: 16, height: 16)
            }
            .accessibilityLabel(Text(.mapDiagnosisAccessibilityExpandedClose))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .diagnosisButtonBackground(.surface, in: animationNamespace)
        .accessibilityLabel(Text(.mapDiagnosisAccessibilityResults))
    }

    private var collapsedContent: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    collapsedCircleBackground

                    sparkleIcon(
                        color: variant == .discovery ? .secondary5 : .primary50
                    )
                }
                .frame(width: 46, height: 46)
                .padding(.top, 2)
                .padding(.trailing, 2)

                Text(.mapDiagnosisBadge)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundStyle(.primary50)
                    .padding(.horizontal, 6)
                    .background(.secondary5)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.primary50, lineWidth: 1)
                    }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.mapDiagnosisAccessibilityCollapsed))
    }

    @ViewBuilder private var collapsedCircleBackground: some View {
        switch variant {
        case .discovery:
            Capsule()
                .fill(diagnosisButtonGradient)
                .diagnosisButtonMorphingBackground(in: animationNamespace)

        case .matches:
            Capsule()
                .fill(.common0)
                .diagnosisButtonMorphingBackground(in: animationNamespace)
        }
    }

    private func sparkleIcon(color: Color) -> some View {
        Image(.sparkleFill24)
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(color)
            .frame(width: 24, height: 24)
    }
}

private enum DiagnosisButtonBackground {
    case gradient
    case surface
}

private struct DiagnosisButtonBackgroundModifier: ViewModifier {
    let background: DiagnosisButtonBackground
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        content
            .background {
                switch background {
                case .gradient:
                    Capsule()
                        .fill(diagnosisButtonGradient)
                        .diagnosisButtonMorphingBackground(in: namespace)

                case .surface:
                    Capsule()
                        .fill(.common0)
                        .diagnosisButtonMorphingBackground(in: namespace)
                }
            }
    }
}

private var diagnosisButtonGradient: LinearGradient {
    LinearGradient(
        colors: [.primary40, .primary50],
        startPoint: .leading,
        endPoint: .trailing
    )
}

private extension View {
    func diagnosisButtonBackground(
        _ background: DiagnosisButtonBackground,
        in namespace: Namespace.ID
    ) -> some View {
        modifier(
            DiagnosisButtonBackgroundModifier(
                background: background,
                namespace: namespace
            )
        )
    }

    func diagnosisButtonMorphingBackground(in namespace: Namespace.ID) -> some View {
        overlay {
            Capsule()
                .stroke(.primary50, lineWidth: 1)
        }
        .matchedGeometryEffect(
            id: DiagnosisButtonAnimationID.background,
            in: namespace
        )
        .kohereElevation(.normalXSmall, shape: .capsule)
    }
}

private enum DiagnosisButtonAnimationID {
    static let background = "MapDiagnosisButton.background"
}
