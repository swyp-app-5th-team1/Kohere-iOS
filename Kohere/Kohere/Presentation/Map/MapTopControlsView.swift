//
//  MapTopControlsView.swift
//  Kohere
//
//  Created by Codex on 7/7/26.
//

import SwiftUI

struct MapTopControlsView: View {
    let searchDisplayText: String?
    let showsResearchButton: Bool
    let onSearchTapped: () -> Void
    let onSearchDisplayClearTapped: () -> Void
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
        HStack(spacing: 0) {
            Button(action: onSearchTapped) {
                HStack(spacing: 12) {
                    Image(.search24)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.neutral70)

                    Text(searchDisplayText ?? "지역, 학교, 지하철역")
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(searchDisplayText == nil ? .coolNeutral20 : .coolNeutral80)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(searchDisplayText ?? "지역, 학교, 지하철역 검색")

            if searchDisplayText != nil {
                Button(action: onSearchDisplayClearTapped) {
                    Image(.closeThick16)
                        .renderingMode(.template)
                        .foregroundStyle(.labelAlternative)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색 결과 지우기")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, searchDisplayText == nil ? 16 : 2)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .kohereSurface(
            background: .common0,
            shape: .roundedRectangle(cornerRadius: 16),
            elevation: .normalXSmall
        )
    }

    private var researchButton: some View {
        Button(action: onResearchTapped) {
            HStack(spacing: 12) {
                Image("refresh_16")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.blue100)

                Text("map.researchAreaButton")
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
