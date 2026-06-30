//
//  ListingDetailHeroSection.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailHeroSection: View {
    let overview: ListingDetailOverviewModel

    var body: some View {
        VStack(spacing: 0) {
            heroImage
            ListingDetailOverviewSection(overview: overview)
        }
        .background(.common0)
    }

    private var heroImage: some View {
        Image(.roomPlaceholder)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 267)
            .clipped()
            .overlay {
                Color.common100.opacity(0.2)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(overview.imageCountText)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundStyle(.common0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.backgroundTransparentAlternative)
                    .clipShape(Capsule())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
    }
}
