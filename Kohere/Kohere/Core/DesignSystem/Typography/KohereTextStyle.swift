//
//  KohereTextStyle.swift
//  Kohere
//
//  Created by Codex on 6/16/26.
//

import SwiftUI

enum KohereTextStyle: CaseIterable {
    case display1Bold
    case display2Bold
    case heading1Bold
    case heading2Bold
    case heading2Semibold
    case heading3Semibold
    case body1Regular
    case body2Regular
    case body3Regular
    case label1Semibold
    case label1Medium
    case label2Semibold
    case label2Medium
    case label3Semibold
    case label3Medium
    case caption1Regular
    case caption2Semibold
    case caption2Medium
    case caption2Regular

    var tokenName: String {
        switch self {
        case .display1Bold: "Display1-bold"
        case .display2Bold: "Display2-bold"
        case .heading1Bold: "Heading1-bold"
        case .heading2Bold: "Heading2-bold"
        case .heading2Semibold: "Heading2-semibold"
        case .heading3Semibold: "Heading3-semibold"
        case .body1Regular: "Body1-regular"
        case .body2Regular: "Body2-regular"
        case .body3Regular: "Body3-regular"
        case .label1Semibold: "Label1-semibold"
        case .label1Medium: "Label1-medium"
        case .label2Semibold: "Label2-semibold"
        case .label2Medium: "Label2-medium"
        case .label3Semibold: "Label3-semibold"
        case .label3Medium: "Label3-medium"
        case .caption1Regular: "Caption1-regular"
        case .caption2Semibold: "Caption2-semibold"
        case .caption2Medium: "Caption2-medium"
        case .caption2Regular: "Caption2-regular"
        }
    }

    var fontFamily: String {
        "Pretendard JP"
    }

    var fontName: String {
        switch self {
        case .display1Bold, .display2Bold, .heading1Bold, .heading2Bold:
            "PretendardJP-Bold"
        case .heading2Semibold,
             .heading3Semibold,
             .label1Semibold,
             .label2Semibold,
             .label3Semibold,
             .caption2Semibold:
            "PretendardJP-SemiBold"
        case .label1Medium, .label2Medium, .label3Medium, .caption2Medium:
            "PretendardJP-Medium"
        case .body1Regular, .body2Regular, .body3Regular, .caption1Regular, .caption2Regular:
            "PretendardJP-Regular"
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .display1Bold: 32
        case .display2Bold: 28
        case .heading1Bold: 24
        case .heading2Bold, .heading2Semibold: 20
        case .heading3Semibold: 18
        case .body1Regular, .label1Semibold, .label1Medium: 16
        case .body2Regular, .label2Semibold, .label2Medium: 14
        case .body3Regular: 13
        case .label3Semibold, .label3Medium, .caption1Regular: 12
        case .caption2Semibold, .caption2Medium, .caption2Regular: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display1Bold, .display2Bold, .heading1Bold, .heading2Bold:
            .bold
        case .heading2Semibold,
             .heading3Semibold,
             .label1Semibold,
             .label2Semibold,
             .label3Semibold,
             .caption2Semibold:
            .semibold
        case .label1Medium, .label2Medium, .label3Medium, .caption2Medium:
            .medium
        case .body1Regular, .body2Regular, .body3Regular, .caption1Regular, .caption2Regular:
            .regular
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .display1Bold: 40
        case .display2Bold: 36
        case .heading1Bold: 32
        case .heading2Bold, .heading2Semibold: 28
        case .heading3Semibold, .body1Regular, .label1Semibold, .label1Medium: 24
        case .body2Regular, .label2Semibold, .label2Medium: 20
        case .body3Regular: 18
        case .label3Semibold, .label3Medium, .caption1Regular: 16
        case .caption2Semibold, .caption2Medium, .caption2Regular: 14
        }
    }

    var letterSpacingPercentage: CGFloat {
        0
    }

    var font: Font {
        .custom(fontName, size: fontSize)
    }

    var lineSpacing: CGFloat {
        max(lineHeight - fontSize, 0)
    }

    var letterSpacing: CGFloat {
        fontSize * letterSpacingPercentage / 100
    }
}

private struct KohereTextStyleModifier: ViewModifier {
    let style: KohereTextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .kerning(style.letterSpacing)
            .lineSpacing(style.lineSpacing)
    }
}

extension View {
    func kohereTextStyle(_ style: KohereTextStyle) -> some View {
        modifier(KohereTextStyleModifier(style: style))
    }
}
