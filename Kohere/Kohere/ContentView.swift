//
//  ContentView.swift
//  Kohere
//
//  Created by 송규섭 on 6/11/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Design System")
                        .kohereTextStyle(.display1Bold)
                    Text("Pretendard JP와 elevation token을 확인하는 임시 샘플입니다.")
                        .kohereTextStyle(.body2Regular)
                }

                typographySection(
                    title: "Display / Heading",
                    items: [
                        ("Display1-bold", .display1Bold),
                        ("Display2-bold", .display2Bold),
                        ("Heading1-bold", .heading1Bold),
                        ("Heading2-semibold", .heading2Semibold),
                        ("Heading3-semibold", .heading3Semibold)
                    ]
                )

                typographySection(
                    title: "Body",
                    items: [
                        ("Body1-regular", .body1Regular),
                        ("Body2-regular", .body2Regular),
                        ("Body3-regular", .body3Regular)
                    ]
                )

                typographySection(
                    title: "Label / Caption",
                    items: [
                        ("Label1-semibold", .label1Semibold),
                        ("Label2-medium", .label2Medium),
                        ("Label3-medium", .label3Medium),
                        ("Caption1-regular", .caption1Regular),
                        ("Caption2-semibold", .caption2Semibold)
                    ]
                )

                elevationSection()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(.backgroundNormalAlternative)
        }
    }

    private func typographySection(
        title: String,
        items: [(String, KohereTextStyle)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .kohereTextStyle(.label1Semibold)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.0) { item in
                    Text("\(item.0) - 한국어 English 日本語")
                        .kohereTextStyle(item.1)
                }
            }
        }
    }

    private func elevationSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Elevation")
                .kohereTextStyle(.label1Semibold)

            VStack(spacing: 20) {
                ForEach(KohereElevation.allCases, id: \.self) { elevation in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(elevation.tokenName)
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.labelNormal)
                        Text("RoundedRectangle / 16")
                            .kohereTextStyle(.caption2Regular)
                            .foregroundStyle(.labelAlternative)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                    .padding(16)
                    .kohereSurface(
                        background: .backgroundElevatedNormal,
                        shape: .roundedRectangle(cornerRadius: 16),
                        elevation: elevation
                    )
                }
            }
            .padding(.vertical, 12)
        }
    }
}
