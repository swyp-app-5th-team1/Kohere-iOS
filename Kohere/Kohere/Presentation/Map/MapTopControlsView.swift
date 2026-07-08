//
//  MapTopControlsView.swift
//  Kohere
//
//  Created by Codex on 7/7/26.
//

import SwiftUI

struct MapTopControlsView: View {
    let showsResearchButton: Bool
    let onSearchTapped: () -> Void
    let onResearchTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            searchBar

            if showsResearchButton {
                researchButton
            }
        }
        .padding(.horizontal, 20)
    }

    private var searchBar: some View {
        Button(action: onSearchTapped) {
            HStack(spacing: 12) {
                Image(.search24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.neutral70)

                Text("지역, 학교, 지하철역")
                    .kohereTextStyle(.label1Medium)
                    .foregroundStyle(.coolNeutral20)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .kohereSurface(
                background: .common0,
                shape: .roundedRectangle(cornerRadius: 16),
                elevation: .normalXSmall
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("지역, 학교, 지하철역 검색")
    }

    private var researchButton: some View {
        Button(action: onResearchTapped) {
            HStack(spacing: 12) {
                Image("refresh_16")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.blue100)

                Text("이 지역에서 다시 탐색")
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.blue100)
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .kohereSurface(
                background: .common0,
                shape: .capsule,
                elevation: .normalXSmall
            )
        }
        .buttonStyle(.plain)
    }
}
